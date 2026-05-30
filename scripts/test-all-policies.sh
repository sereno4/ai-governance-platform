#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " AI Governance Platform — Policy Tests"
echo "========================================"

# --- TESTE 1: FinOps block ---
echo ""
echo "[1/3] FinOps block (dev + 8 GPUs) — deve BLOQUEAR:"
kubectl delete deployment vllm-abusive -n team-dev 2>/dev/null || true
OUT=$(kubectl apply -f workloads/abusive/inference-premium-dev.yaml 2>&1)
echo "  $OUT" | head -3
echo "$OUT" | grep -q "denied\|FinOps\|Error from server" && \
  echo "  ✓ BLOQUEADO" || echo "  ✗ PASSOU (erro)"

# --- TESTE 2: Resource limits ---
echo ""
echo "[2/3] Resource limits (GPU sem limits) — deve BLOQUEAR:"
cat << 'YAML' | kubectl apply -f - 2>&1 | head -4
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-no-limits
  namespace: team-mlops
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vllm-no-limits
  template:
    metadata:
      labels:
        app: vllm-no-limits
    spec:
      containers:
        - name: vllm
          image: vllm/vllm-openai:latest
          resources:
            requests:
              nvidia.com/gpu: "2"
              memory: "16Gi"
YAML
kubectl delete deployment vllm-no-limits -n team-mlops 2>/dev/null || true

# --- TESTE 3: Mutating sidecar ---
echo ""
echo "[3/3] Mutating — GPTCache injetado em deploy vLLM (team-mlops):"
kubectl delete deployment vllm-standard -n team-mlops 2>/dev/null || true
sleep 2
kubectl apply -f workloads/valid/inference-standard.yaml
sleep 3
CONTAINERS=$(kubectl get deployment vllm-standard -n team-mlops \
  -o jsonpath='{.spec.template.spec.containers[*].name}')
echo "  Containers no pod: $CONTAINERS"
echo "$CONTAINERS" | grep -q "gptcache" && \
  echo "  ✓ GPTCache INJETADO automaticamente" || \
  echo "  ✗ GPTCache nao encontrado (verificar label ai-governance/cache=enabled)"

echo ""
echo "========================================"
echo " Resumo das políticas ativas:"
kubectl get validatingpolicy -A --no-headers 2>/dev/null
kubectl get clusterpolicy --no-headers 2>/dev/null
echo "========================================"
