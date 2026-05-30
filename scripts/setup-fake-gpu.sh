#!/usr/bin/env bash
set -euo pipefail

echo "==> Anunciando nvidia.com/gpu nos nós workers..."

for NODE in ai-governance-worker ai-governance-worker2; do
  kubectl proxy --port=0 &>/dev/null &
  PROXY_PID=$!
  sleep 1

  kubectl patch node "$NODE" \
    --subresource=status \
    --type=merge \
    -p '{"status":{"capacity":{"nvidia.com/gpu":"8"},"allocatable":{"nvidia.com/gpu":"8"}}}'

  echo "  ✓ $NODE → 8 GPUs anunciadas"
  kill $PROXY_PID 2>/dev/null || true
done

echo ""
echo "==> Labels de GPU nos nós (simulando tiers):"
kubectl label node ai-governance-worker  gpu-type=a100 gpu-tier=standard --overwrite
kubectl label node ai-governance-worker2 gpu-type=h100 gpu-tier=premium  --overwrite

echo ""
echo "==> Verificando recursos alocáveis:"
kubectl get nodes -o custom-columns=\
"NAME:.metadata.name,\
GPU:.status.allocatable['nvidia\.com/gpu'],\
TIER:.metadata.labels['gpu-tier']"
