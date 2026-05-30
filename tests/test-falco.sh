#!/bin/bash
echo "========================================================"
echo " Falco AI Governance — Teste de Detecção de Ameaças"
echo "========================================================"

NS=team-mlops
FALCO_POD=$(kubectl get pod -n falco -l app.kubernetes.io/name=falco \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$FALCO_POD" ]; then
  echo "❌ Falco pod não encontrado"
  exit 1
fi
echo "  Falco pod: $FALCO_POD"

# Criar pod de teste persistente
kubectl delete pod falco-test -n $NS --ignore-not-found &>/dev/null
kubectl run falco-test \
  --image=ubuntu:22.04 \
  --namespace=$NS \
  --restart=Never \
  --command -- sleep 120 &>/dev/null
sleep 5

echo ""
echo "[1/3] Simulando acesso não autorizado ao modelo..."
kubectl exec falco-test -n $NS -- \
  sh -c "touch /tmp/model.safetensors && cat /tmp/model.safetensors" \
  2>/dev/null || true
sleep 2

echo ""
echo "[2/3] Simulando processo suspeito (shell + download)..."
kubectl exec falco-test -n $NS -- \
  sh -c "bash -c 'echo suspicious'" \
  2>/dev/null || true
sleep 2

echo ""
echo "[3/3] Simulando exfiltração (conexão externa)..."
kubectl exec falco-test -n $NS -- \
  sh -c "curl -s --max-time 2 http://8.8.8.8 || true" \
  2>/dev/null || true
sleep 3

# Coletar alertas do Falco
echo ""
echo "========================================================"
echo " Alertas capturados pelo Falco:"
echo "========================================================"
kubectl logs $FALCO_POD -n falco --since=30s 2>/dev/null \
  | grep -i "ai-gov\|team-mlops\|safetensors\|CRITICAL\|WARNING" \
  | tail -20

kubectl delete pod falco-test -n $NS --ignore-not-found &>/dev/null
echo ""
echo "✅ Teste concluído — ver alertas acima"
echo "========================================================"
