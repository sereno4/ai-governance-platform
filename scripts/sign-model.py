import hashlib
import json
import boto3
import datetime
from botocore.client import Config

MINIO_ENDPOINT = "http://localhost:9000"
MODEL_PATH     = "/tmp/model.safetensors"
MODEL_BUCKET   = "models"
MODEL_KEY      = "model.safetensors"
MANIFEST_KEY   = "model.c2pa.json"

with open(MODEL_PATH, "wb") as f:
    f.write(b"fake-safetensors-model-weights-v1" * 1000)

h = hashlib.sha256()
with open(MODEL_PATH, "rb") as f:
    for chunk in iter(lambda: f.read(8192), b""):
        h.update(chunk)
model_hash = h.hexdigest()

manifest = {
    "schema":      "c2pa/1.0",
    "model_key":   MODEL_KEY,
    "model_hash":  model_hash,
    "signed_by":   "ci-pipeline@gitlab",
    "signed_at":   datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "pipeline_id": "gitlab-ci-12345",
    "assertions": [
        {"label": "c2pa.training.data", "value": "curated-dataset-v3"},
        {"label": "c2pa.model.type",    "value": "llm-inference"},
    ],
}

s3 = boto3.client(
    "s3",
    endpoint_url=MINIO_ENDPOINT,
    aws_access_key_id="minioadmin",
    aws_secret_access_key="minioadmin",
    config=Config(signature_version="s3v4"),
)

try:
    s3.create_bucket(Bucket=MODEL_BUCKET)
except Exception:
    pass

s3.upload_file(MODEL_PATH, MODEL_BUCKET, MODEL_KEY)
s3.put_object(Bucket=MODEL_BUCKET, Key=MANIFEST_KEY,
              Body=json.dumps(manifest, indent=2).encode())

print(f"✅ Modelo enviado:   s3://{MODEL_BUCKET}/{MODEL_KEY}")
print(f"✅ Manifesto C2PA:  s3://{MODEL_BUCKET}/{MANIFEST_KEY}")
print(f"   hash SHA-256:    {model_hash}")
