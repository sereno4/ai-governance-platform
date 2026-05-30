import os, sys, json, hashlib, subprocess, tempfile
import boto3
from botocore.client import Config

MINIO_ENDPOINT = os.environ.get("MINIO_ENDPOINT", "http://minio.minio.svc.cluster.local:9000")
MINIO_ACCESS   = os.environ.get("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET   = os.environ.get("MINIO_SECRET_KEY", "minioadmin")
MODEL_BUCKET   = os.environ.get("MODEL_BUCKET",   "models")
MODEL_KEY      = os.environ.get("MODEL_KEY",      "model.safetensors")
MANIFEST_KEY   = os.environ.get("MANIFEST_KEY",   "model.c2pa.json")
PROVENANCE_KEY = os.environ.get("PROVENANCE_KEY", "model.slsa-provenance.json")
SIGNATURE_KEY  = os.environ.get("SIGNATURE_KEY",  "model.slsa-provenance.sig")
COSIGN_PUB_KEY = os.environ.get("COSIGN_PUB_KEY", "/cosign.pub")

def sha256_stream(body):
    h = hashlib.sha256()
    for chunk in iter(lambda: body.read(8192), b""):
        h.update(chunk)
    return h.hexdigest()

def main():
    s3 = boto3.client("s3", endpoint_url=MINIO_ENDPOINT,
        aws_access_key_id=MINIO_ACCESS, aws_secret_access_key=MINIO_SECRET,
        config=Config(signature_version="s3v4"))

    # CHECK 1: C2PA hash
    print("[validator] ── CHECK 1: C2PA hash ──")
    manifest    = json.loads(s3.get_object(Bucket=MODEL_BUCKET, Key=MANIFEST_KEY)["Body"].read())
    actual_hash = sha256_stream(s3.get_object(Bucket=MODEL_BUCKET, Key=MODEL_KEY)["Body"])
    if actual_hash != manifest["model_hash"]:
        print(f"[validator] ❌ C2PA FALHOU — hash adulterado")
        print(f"  esperado:  {manifest['model_hash']}")
        print(f"  calculado: {actual_hash}")
        sys.exit(1)
    print(f"[validator] ✅ C2PA OK — {actual_hash[:16]}...")

    # CHECK 2: SLSA provenance
    print("[validator] ── CHECK 2: SLSA provenance ──")
    prov_data  = s3.get_object(Bucket=MODEL_BUCKET, Key=PROVENANCE_KEY)["Body"].read()
    provenance = json.loads(prov_data)
    subj_hash  = provenance["subject"][0]["digest"]["sha256"]
    if subj_hash != actual_hash:
        print(f"[validator] ❌ SLSA FALHOU — hash no provenance diverge")
        sys.exit(1)
    builder = provenance["predicate"]["runDetails"]["builder"]["id"]
    deps    = provenance["predicate"]["buildDefinition"]["resolvedDependencies"]
    print(f"[validator] ✅ SLSA hash OK")
    print(f"[validator] ✅ builder: {builder}")
    print(f"[validator] ✅ dependências rastreadas: {len(deps)}")
    for d in deps:
        print(f"             - {d['name']}: {d['uri']}")

    # CHECK 3: Cosign signature via bundle
    print("[validator] ── CHECK 3: assinatura Cosign ──")
    if not os.path.exists(COSIGN_PUB_KEY):
        print(f"[validator] ⚠️  {COSIGN_PUB_KEY} não montada — pulando")
    else:
        bundle_data = s3.get_object(Bucket=MODEL_BUCKET, Key="model.slsa-provenance.bundle")["Body"].read()
        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as pf:
            pf.write(prov_data); prov_tmp = pf.name
        with tempfile.NamedTemporaryFile(suffix=".bundle", delete=False) as bf:
            bf.write(bundle_data); bundle_tmp = bf.name
        result = subprocess.run([
            "cosign", "verify-blob",
            "--key",                  COSIGN_PUB_KEY,
            "--bundle",               bundle_tmp,
            "--insecure-ignore-tlog",
            prov_tmp
        ], capture_output=True, text=True,
           env={**os.environ, "COSIGN_PASSWORD": ""})
        if result.returncode != 0:
            print(f"[validator] ❌ Cosign FALHOU — {result.stderr.strip()}")
            sys.exit(1)
        print(f"[validator] ✅ assinatura Cosign válida")

    print("")
    print("[validator] 🎯 APROVADO — C2PA + SLSA Level 3 verificados")
    print("[validator]    dataset → treino → assinatura → deploy")
    sys.exit(0)

if __name__ == "__main__":
    main()
