#!/usr/bin/env bash
# prepare-for-k9s-screenshot.sh
# Prepara o cluster com workloads visuais e abre o k9s

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     PREPARANDO CLUSTER PARA PRINT PROFISSIONAL K9S            ║"
echo "╚════════════════════════════════════════════════════════════════╝"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Criar deploy válido em production (vai mostrar sidecar)
echo ""
echo -e "${GREEN}==>${NC} Criando deploy production com sidecar GPTCache..."
cat << 'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-production
  namespace: team-mlops
  labels:
    app.kubernetes.io/name: vllm
    ai-governance/cache: "enabled"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vllm-production
  template:
    metadata:
      labels:
        app: vllm-production
        app.kubernetes.io/name: vllm
        ai-governance/cache: "enabled"
    spec:
      nodeSelector:
        gpu-tier: standard
      containers:
        - name: vllm
          image: vllm/vllm-openai:latest
          resources:
            limits:
              nvidia.com/gpu: "2"
              memory: "32Gi"
            requests:
              nvidia.com/gpu: "2"
              memory: "32Gi"
YAML

# 2. Criar deploy em research (staging)
echo -e "${GREEN}==>${NC} Criando deploy staging..."
cat << 'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-research
  namespace: team-research
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vllm-research
  template:
    metadata:
      labels:
        app: vllm-research
    spec:
      nodeSelector:
        gpu-tier: standard
      containers:
        - name: vllm
          image: vllm/vllm-openai:latest
          resources:
            limits:
              nvidia.com/gpu: "1"
              memory: "16Gi"
            requests:
              nvidia.com/gpu: "1"
              memory: "16Gi"
YAML

# 3. Criar um pod que vai falhar (simulando bloqueio) em dev
echo -e "${GREEN}==>${NC} Criando pod bloqueado em dev (vai mostrar erro)..."
cat << 'YAML' | kubectl apply -f - >/dev/null 2>&1 || true
apiVersion: v1
kind: Pod
metadata:
  name: vllm-abusive-blocked
  namespace: team-dev
spec:
  containers:
    - name: vllm
      image: vllm/vllm-openai:latest
      resources:
        requests:
          nvidia.com/gpu: "8"
        limits:
          nvidia.com/gpu: "8"
YAML

sleep 3

echo ""
echo "========================================"
echo "  STATUS DOS RECURSOS"
echo "========================================"
kubectl get deployments -A 2>/dev/null || true
echo ""
kubectl get pods -A 2>/dev/null | grep -E "vllm|NAME" || true

echo ""
echo "========================================"
echo "  ABRINDO K9S..."
echo "========================================"
echo ""
echo "Comandos úteis dentro do k9s:"
echo "  :deployments     <- Ver deploys por namespace"
echo "  :pods            <- Ver pods (olhe o 2/2 no sidecar!)"
echo "  :policies        <- Ver Kyverno policies"
echo "  :ns              <- Ver namespaces com labels"
echo "  :nodes           <- Ver nodes com labels GPU"
echo ""
echo "  Pressione '0' para ver TODOS os namespaces"
echo "  Pressione 'w' para wide mode"
echo "  Pressione 'd' para descrição detalhada"
echo ""
echo "🎯 PRINTS RECOMENDADOS:"
echo "   1. :deployments (wide, todos NS) -> mostra bloqueio em dev"
echo "   2. :pods team-mlops -> mostra 2/2 containers (sidecar!)"
echo "   3. :policies -> mostra 3 políticas ativas"
echo ""

read -p "Pressione ENTER para abrir o k9s..."

# Abrir k9s na view de deployments
echo "Abrindo k9s..."
k9s --context kind-ai-governance --command deployments

# Limpeza ao sair
echo ""
echo "==> Limpando recursos de demo..."
kubectl delete pod vllm-abusive-blocked -n team-dev --force --grace-period=0 2>/dev/null || true
kubectl delete deployment vllm-production -n team-mlops --ignore-not-found=true 2>/dev/null || true
kubectl delete deployment vllm-research -n team-research --ignore-not-found=true 2>/dev/null || true
echo "✅ Limpo!"
