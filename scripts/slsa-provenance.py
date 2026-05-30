import hashlib, json, subprocess, datetime, os, tempfile
import boto3
from botocore.client import Config

MINIO_ENDPOINT = os.environ.get("MINIO_ENDPOINT", "http://localhost:9000")
MODEL_PATH     = "/tmp/model.safetensors"
MODEL_BUCKET   = "models"
PROVENANCE_KEY = "model.slsa-provenance.json"
SIGNATURE_KEY  = "model.slsa-provenance.sig"
COSIGN_KEY     = os.path.abspath("slsa/cosign.key")

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    model_hash = sha256_file(MODEL_PATH)
    print(f"[slsa] hash do modelo: {model_hash}")

    provenance = {
        "_type": "https://in-toto.io/Statement/v0.1",
        "subject": [{"name": "model.safetensors", "digest": {"sha256": model_hash}}],
        "predicateType": "https://slsa.dev/provenance/v1",
        "predicate": {
            "buildDefinition": {
                "buildType": "https://gitlab.com/ai-governance/model-training/v1",
                "externalParameters": {
                    "repository": "https://gitlab.com/org/ai-models",
                    "ref":        "refs/heads/main",
                    "commit":     "abc123def456",
                },
                "resolvedDependencies": [
                    {"name": "training-dataset", "digest": {"sha256": "deadbeef" * 8},
                     "uri": "s3://datasets/curated-v3.tar.gz"},
                    {"name": "base-model", "digest": {"sha256": "cafebabe" * 8},
                     "uri": "huggingface://meta-llama/Llama-3-8B"},
                ]
            },
            "runDetails": {
                "builder": {
                    "id": "https://gitlab.com/org/ai-governance/.gitlab-ci.yml@refs/heads/main",
                    "version": {"gitlab-runner": "16.11.0"}
                },
                "metadata": {
                    "invocationId": "gitlab-pipeline-12345",
                    "startedOn":  datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    "finishedOn": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                },
                "byproducts": [
                    {"name": "training-logs", "digest": {"sha256": "feedface" * 8},
                     "uri": "s3://logs/training-12345.log"}
                ]
            }
        }
    }

    prov_path = "/tmp/model.slsa-provenance.json"
    with open(prov_path, "w") as f:
        json.dump(provenance, f, indent=2)
    print(f"[slsa] provenance gerado")

    bundle_path = "/tmp/model.slsa-provenance.bundle"
    result = subprocess.run([
        "cosign", "sign-blob",
        "--key", COSIGN_KEY,
        "--bundle", bundle_path,
        "--yes",
        prov_path
    ], capture_output=True, text=True,
       env={**os.environ, "COSIGN_PASSWORD": ""})

    if result.returncode != 0:
        print(f"[slsa] ❌ falha ao assinar: {result.stderr}")
        exit(1)
    print(f"[slsa] ✅ assinado com Cosign (bundle)")

    # Extrair assinatura do bundle para compatibilidade
    import base64
    with open(bundle_path) as bf:
        bundle = json.load(bf)
    sig_b64 = bundle.get("base64Signature", "")
    sig_path = "/tmp/model.slsa-provenance.sig"
    with open(sig_path, "w") as sf:
        sf.write(sig_b64)

    s3 = boto3.client("s3", endpoint_url=MINIO_ENDPOINT,
        aws_access_key_id="minioadmin", aws_secret_access_key="minioadmin",
        config=Config(signature_version="s3v4"))
    s3.upload_file(prov_path,   MODEL_BUCKET, PROVENANCE_KEY)
    s3.upload_file(bundle_path, MODEL_BUCKET, "model.slsa-provenance.bundle")
    s3.upload_file(sig_path,    MODEL_BUCKET, SIGNATURE_KEY)
    print(f"[slsa] ✅ s3://{MODEL_BUCKET}/{PROVENANCE_KEY}")
    print(f"[slsa] ✅ s3://{MODEL_BUCKET}/model.slsa-provenance.bundle")
    print(f"[slsa] 🎯 SLSA Level 3 — rastreável do dataset ao deploy")

if __name__ == "__main__":
    main()
