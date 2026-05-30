#!/bin/bash
echo "========================================================"
echo " AI Governance Platform — Suite Completa de Testes"
echo " Cluster: $(kubectl config current-context)"
echo " Kyverno: $(kubectl get deployment kyverno-admission-controller -n kyverno -o jsonpath='{.metadata.labels.app\.kubernetes\.io/version}' 2>/dev/null)"
echo "========================================================"

PASS=0; FAIL=0
TS=$(date +%s)

check() {
  if [ "$2" = "pass" ]; then echo "  ✅ $1"; ((PASS++))
  else echo "  ❌ $1"; ((FAIL++))
  fi
}

kubectl get namespace team-mlops &>/dev/null || kubectl create namespace team-mlops &>/dev/null

# ─── FASE 1: FinOps ───────────────────────────────────────
echo ""
echo "[FASE 1] FinOps — GPU Governance"

cat > /tmp/test-gpu.yaml << YAML
apiVersion: v1
kind: Pod
metadata:
  name: test-gpu-${TS}
  namespace: team-mlops
spec:
  nodeSelector:
    env: dev
  containers:
    - name: c
      image: nginx:alpine
      resources:
        limits:
          nvidia.com/gpu: "8"
  restartPolicy: Never
YAML
OUT=$(kubectl apply -f /tmp/test-gpu.yaml 2>&1)
kubectl delete pod test-gpu-${TS} -n team-mlops --ignore-not-found &>/dev/null
if echo "$OUT" | grep -qi "block\|denied\|violation\|FinOps\|forbidden"; then
  check "dev + 8 GPUs bloqueado" pass
else
  check "dev + 8 GPUs bloqueado (output: $OUT)" fail
fi

cat > /tmp/test-premium.yaml << YAML
apiVersion: v1
kind: Pod
metadata:
  name: test-premium-${TS}
  namespace: team-mlops
spec:
  nodeSelector:
    env: dev
    gpu-tier: premium
  containers:
    - name: c
      image: nginx:alpine
  restartPolicy: Never
YAML
OUT=$(kubectl apply -f /tmp/test-premium.yaml 2>&1)
kubectl delete pod test-premium-${TS} -n team-mlops --ignore-not-found &>/dev/null
if echo "$OUT" | grep -qi "block\|denied\|violation\|FinOps\|forbidden"; then
  check "dev + gpu-tier=premium bloqueado" pass
else
  check "dev + gpu-tier=premium bloqueado (output: $OUT)" fail
fi

# ─── FASE 2: GPTCache ─────────────────────────────────────
echo ""
echo "[FASE 2] Mutating — GPTCache Sidecar"

cat > /tmp/test-gpt.yaml << YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-gpt-${TS}
  namespace: team-mlops
  labels:
    app.kubernetes.io/name: vllm
    ai-governance/cache: enabled
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-gpt
  template:
    metadata:
      labels:
        app: test-gpt
        app.kubernetes.io/name: vllm
        ai-governance/cache: enabled
    spec:
      containers:
        - name: vllm
          image: nginx:alpine
YAML
kubectl delete deployment test-gpt-${TS} -n team-mlops --ignore-not-found &>/dev/null
kubectl apply -f /tmp/test-gpt.yaml &>/dev/null
sleep 6
CONTAINERS=$(kubectl get deployment test-gpt-${TS} -n team-mlops   -o jsonpath="{.spec.template.spec.containers[*].name}" 2>/dev/null)
echo "  containers: $CONTAINERS"
if echo "$CONTAINERS" | grep -q "gptcache"; then
  check "sidecar GPTCache injetado em Deployment" pass
else
  check "sidecar GPTCache NÃO injetado" fail
fi
kubectl delete deployment test-gpt-${TS} -n team-mlops --ignore-not-found &>/dev/null

# ─── FASE 3: C2PA — Modelo legítimo ───────────────────────
echo ""
echo "[FASE 3] C2PA — Modelo Legítimo"

kubectl delete pod test-valid-${TS} -n team-mlops --ignore-not-found &>/dev/null
kubectl run test-valid-${TS}   --image=nginx:alpine --namespace=team-mlops   --labels="c2pa-validation=required" --restart=Never &>/dev/null

EXIT=""
for i in $(seq 1 18); do
  sleep 5
  EXIT=$(kubectl get pod test-valid-${TS} -n team-mlops     -o jsonpath="{.status.initContainerStatuses[0].state.terminated.exitCode}" 2>/dev/null)
  [ -n "$EXIT" ] && break
done
if [ "$EXIT" = "0" ]; then
  check "modelo legítimo aceito (exit 0)" pass
else
  check "modelo legítimo rejeitado — exit=$EXIT" fail
fi
kubectl delete pod test-valid-${TS} -n team-mlops --ignore-not-found &>/dev/null

# ─── FASE 4: C2PA — Adulteração ───────────────────────────
echo ""
echo "[FASE 4] C2PA — Detecção de Adulteração"

echo "  adulterando modelo..."
kubectl port-forward -n minio svc/minio 9000:9000 &>/dev/null &
PF_PID=$!
sleep 4
python3 -c "
import boto3
from botocore.client import Config
s3 = boto3.client('s3', endpoint_url='http://localhost:9000',
    aws_access_key_id='minioadmin', aws_secret_access_key='minioadmin',
    config=Config(signature_version='s3v4'))
with open('/tmp/tampered.safetensors', 'wb') as f:
    f.write(b'MALICIOUS-WEIGHTS' * 1000)
s3.upload_file('/tmp/tampered.safetensors', 'models', 'model.safetensors')
print('  💀 modelo adulterado no MinIO')
"
kill $PF_PID 2>/dev/null
sleep 2

kubectl delete pod test-attack-${TS} -n team-mlops --ignore-not-found &>/dev/null
kubectl run test-attack-${TS}   --image=nginx:alpine --namespace=team-mlops   --labels="c2pa-validation=required" --restart=Never &>/dev/null

EXIT=""
for i in $(seq 1 18); do
  sleep 5
  EXIT=$(kubectl get pod test-attack-${TS} -n team-mlops     -o jsonpath="{.status.initContainerStatuses[0].state.terminated.exitCode}" 2>/dev/null)
  [ -n "$EXIT" ] && break
done
if [ "$EXIT" = "1" ]; then
  check "modelo adulterado bloqueado (exit 1)" pass
else
  check "modelo adulterado NÃO bloqueado — exit=$EXIT" fail
fi
kubectl delete pod test-attack-${TS} -n team-mlops --ignore-not-found &>/dev/null

echo "  restaurando modelo legítimo..."
kubectl port-forward -n minio svc/minio 9000:9000 &>/dev/null &
PF_PID=$!
sleep 4
python scripts/sign-model.py &>/dev/null
kill $PF_PID 2>/dev/null
echo "  ✅ modelo restaurado"

# ─── RESULTADO ────────────────────────────────────────────
echo ""
echo "========================================================"
echo " RESULTADO FINAL"
echo "========================================================"
printf "  Passaram : %s\n  Falharam : %s\n" "$PASS" "$FAIL"
echo ""
if [ "$FAIL" = "0" ]; then
  echo "🎉 TODOS OS TESTES PASSARAM"
  echo ""
  echo "  Fase 1 — FinOps  : bloqueia GPUs premium em dev/staging"
  echo "  Fase 2 — Mutating: injeta GPTCache sidecar em Deployments"
  echo "  Fase 3 — C2PA    : modelo legítimo aceito"
  echo "  Fase 4 — C2PA    : adulteração detectada e bloqueada"
  echo ""
  echo "🚀 Portfólio pronto para entrevistas sênior"
else
  echo "⚠️  $FAIL teste(s) falharam — ver detalhes acima"
fi
echo "========================================================"
