#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " AI Governance Platform — Policy Tests"
echo "========================================"

# --- TESTE 1: FinOps block ---
echo ""
echo "[1/3] FinOps block (dev + 8 GPUs) — deve BLOQUEAR:"
kubectl delete deployment vllm-abusive -n team-dev 2>/dev/null || true

# Usa timeout para não travar, captura stderr
OUT=$(timeout 15 kubectl apply -f workloads/abusive/inference-premium-dev.yaml 2>&1) || true
echo "  Output: $OUT"

if echo "$OUT" | grep -qi "denied\|FinOps\|Error from server\|violation\|blocked"; then
    echo "  ✅ BLOQUEADO corretamente"
elif echo "$OUT" | grep -qi "created\|unchanged"; then
    echo "  ❌ PASSOU (deveria ter sido bloqueado!)"
    # Limpa o deploy que passou indevidamente
    kubectl delete deployment vllm-abusive -n team-dev 2>/dev/null || true
else
    echo "  ⚠️  Resultado inconclusivo — verificar política"
fi

# --- TESTE 2: Resource limits ---
echo ""
echo "[2/3] Resource limits (GPU sem limits) — deve BLOQUEAR:"
kubectl delete deployment vllm-no-limits -n team-mlops 2>/dev/null || true

OUT2=$(timeout 15 cat << 'YAML' | kubectl apply -f - 2>&1) || true
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

echo "  Output: $OUT2"

if echo "$OUT2" | grep -qi "denied\|require-gpu-limits\|Error from server\|violation"; then
    echo "  ✅ BLOQUEADO corretamente (sem limits de GPU)"
elif echo "$OUT2" | grep -qi "created\|unchanged"; then
    echo "  ❌ PASSOU (deveria ter sido bloqueado!)"
    kubectl delete deployment vllm-no-limits -n team-mlops 2>/dev/null || true
else
    echo "  ⚠️  Resultado inconclusivo"
fi

# --- TESTE 3: Mutating sidecar ---
echo ""
echo "[3/3] Mutating — GPTCache injetado em deploy vLLM (team-mlops):"
kubectl delete deployment vllm-standard -n team-mlops 2>/dev/null || true
sleep 2

kubectl apply -f workloads/valid/inference-standard.yaml
sleep 3

CONTAINERS=$(kubectl get deployment vllm-standard -n team-mlops \
  -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null) || true

echo "  Containers no pod: $CONTAINERS"

if echo "$CONTAINERS" | grep -q "gptcache"; then
    echo "  ✅ GPTCache INJETADO automaticamente"
else
    echo "  ❌ GPTCache NÃO encontrado"
    echo "  (verificar se o deploy tem label 'ai-governance/cache=enabled')"
fi

# --- RESUMO ---
echo ""
echo "========================================"
echo " Resumo das políticas ativas:"
echo "========================================"
kubectl get validatingpolicy -A --no-headers 2>/dev/null || echo "  (nenhuma ValidatingPolicy)"
kubectl get clusterpolicy --no-headers 2>/dev/null || echo "  (nenhuma ClusterPolicy)"
echo "========================================"
