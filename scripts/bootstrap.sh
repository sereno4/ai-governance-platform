#!/bin/bash
# Reaplicar todas as políticas e infraestrutura após reinício do cluster
set -e
echo "🔧 Bootstrap — AI Governance Platform"

echo ""
echo "[1/4] Kyverno..."
helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno --create-namespace \
  --set admissionController.replicas=1 \
  --wait --timeout 300s
echo "  ✅ Kyverno pronto"

echo ""
echo "[2/4] MinIO..."
kubectl apply -f minio/minio.yaml
kubectl wait --namespace minio --for=condition=ready pod \
  --selector=app=minio --timeout=90s
echo "  ✅ MinIO pronto"

echo ""
echo "[3/4] Políticas Kyverno..."
kubectl apply -f policies/
kubectl get clusterpolicy
echo "  ✅ Políticas aplicadas"

echo ""
echo "[4/4] Modelo assinado no MinIO..."
kubectl port-forward -n minio svc/minio 9000:9000 &>/dev/null &
PF_PID=$!
sleep 4
python scripts/sign-model.py
kill $PF_PID 2>/dev/null
echo "  ✅ Modelo assinado"

echo ""
echo "✅ Bootstrap completo — rode: bash tests/test-suite-completo.sh"

echo ""
echo "[5/5] SLSA provenance..."
kubectl port-forward -n minio svc/minio 9000:9000 &>/dev/null &
PF_PID=$!
sleep 4
MINIO_ENDPOINT=http://localhost:9000 python scripts/slsa-provenance.py
kill $PF_PID 2>/dev/null
echo "  ✅ SLSA provenance assinado"
