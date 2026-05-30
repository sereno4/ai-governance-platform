#!/usr/bin/env bash
set -euo pipefail

echo "==> Removendo cluster Kind antigo (se existir)..."
kind delete cluster --name ai-governance 2>/dev/null && \
  echo "  ✓ Cluster removido" || \
  echo "  (nenhum cluster existia)"

echo "==> Limpando contexto kubectl..."
kubectl config delete-context kind-ai-governance 2>/dev/null || true
kubectl config delete-cluster kind-ai-governance 2>/dev/null || true
kubectl config delete-user kind-ai-governance 2>/dev/null || true

echo "==> Contexto atual após limpeza:"
kubectl config current-context 2>/dev/null || echo "  (nenhum contexto ativo)"
