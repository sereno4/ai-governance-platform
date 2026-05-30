#!/bin/bash
set -e
echo "========================================"
echo " Teste C2PA — Proveniência do Modelo"
echo "========================================"

kubectl get namespace team-mlops &>/dev/null || kubectl create namespace team-mlops

echo ""
echo "[1/2] Pod COM label c2pa-validation=required — deve injetar validator"
kubectl delete pod inference-valid -n team-mlops --ignore-not-found 2>/dev/null
kubectl run inference-valid \
  --image=nginx:alpine \
  --namespace=team-mlops \
  --labels="c2pa-validation=required" \
  --restart=Never 2>/dev/null || true

sleep 5
INIT=$(kubectl get pod inference-valid -n team-mlops \
  -o jsonpath='{.spec.initContainers[*].name}' 2>/dev/null)

if echo "$INIT" | grep -q "c2pa-validator"; then
  echo "  ✅ Init container injetado: $INIT"
else
  echo "  ❌ Init container NÃO injetado"
fi

echo ""
echo "[2/2] Pod SEM label — não deve injetar"
kubectl delete pod inference-nolabel -n team-mlops --ignore-not-found 2>/dev/null
kubectl run inference-nolabel \
  --image=nginx:alpine \
  --namespace=team-mlops \
  --restart=Never 2>/dev/null || true

sleep 3
INIT2=$(kubectl get pod inference-nolabel -n team-mlops \
  -o jsonpath='{.spec.initContainers[*].name}' 2>/dev/null)

if [ -z "$INIT2" ]; then
  echo "  ✅ Sem init container — comportamento correto"
else
  echo "  ⚠️  Init container inesperado: $INIT2"
fi

echo ""
echo "========================================"
echo " Limpando..."
kubectl delete pod inference-valid inference-nolabel -n team-mlops --ignore-not-found
echo " ✅ Concluído"
echo "========================================"
