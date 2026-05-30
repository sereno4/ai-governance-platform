#!/usr/bin/env bash
set -euo pipefail

echo "==> Aplicando política FinOps..."
kubectl apply -f policies/validating/finops-gpu-block.yaml
sleep 5

echo ""
echo "==> Status da política:"
kubectl get validatingpolicy -A

echo ""
echo "==> [TESTE 1] Deploy válido (team-mlops + 2 GPUs) — deve PASSAR:"
if kubectl apply -f workloads/valid/inference-standard.yaml 2>&1; then
  echo "  ✓ Passou como esperado"
else
  echo "  ✗ Falhou inesperadamente"
fi

echo ""
echo "==> [TESTE 2] Deploy abusivo (team-dev + 8 GPUs + premium) — deve ser BLOQUEADO:"
OUTPUT=$(kubectl apply -f workloads/abusive/inference-premium-dev.yaml 2>&1)
echo "  $OUTPUT"
if echo "$OUTPUT" | grep -q "denied\|FinOps violation\|Error from server"; then
  echo "  ✓ Bloqueado como esperado"
else
  echo "  ✗ Passou — política não está funcionando"
fi

echo ""
echo "==> PolicyReports:"
kubectl get policyreport -A --no-headers 2>/dev/null | head -10 || echo "  (nenhum ainda)"
