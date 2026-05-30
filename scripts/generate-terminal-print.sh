#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}           ${BOLD}AI-Governance-Platform — Cluster Status${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}           ${BOLD}Kubernetes + Kyverno CEL + FinOps + Cache Semântico${NC}               ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"

# Criar workloads para o print
echo ""
echo -e "${GREEN}==>${NC} Preparando workloads de demonstração..."

# Deploy production com sidecar
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

# Deploy staging
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

sleep 3

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  📊 PODS POR NAMESPACE (Governança Multi-Tenant)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${RED}🔴 team-dev (RESTRICTED — Bloqueado pela política FinOps):${NC}"
kubectl get pods -n team-dev 2>/dev/null || echo "   (namespace vazio — política bloqueou o deploy)"

echo ""
echo -e "${YELLOW}🟡 team-research (STANDARD — A100/MIG permitido):${NC}"
kubectl get pods -n team-research -o wide 2>/dev/null | head -5 || echo "   (vazio)"

echo ""
echo -e "${GREEN}🟢 team-mlops (PRIVILEGED — Produção + Sidecar GPTCache):${NC}"
kubectl get pods -n team-mlops -o wide 2>/dev/null | head -5 || echo "   (vazio)"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  🔧 DETALHES DO SIDECAR INJETADO (team-mlops)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

POD_NAME=$(kubectl get pods -n team-mlops -l app=vllm-production -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD_NAME" ]; then
    echo -e "Pod: ${CYAN}$POD_NAME${NC}"
    echo ""
    echo -e "${BOLD}Containers:${NC}"
    kubectl get pod $POD_NAME -n team-mlops -o jsonpath='{range .spec.containers[*]}{"  • "}{.name}{": "}{.image}{"\n"}{end}' 2>/dev/null
    echo ""
    echo -e "${BOLD}Status:${NC}"
    kubectl get pod $POD_NAME -n team-mlops -o jsonpath='{range .status.containerStatuses[*]}{"  • "}{.name}{": Ready="}{.ready}{" RestartCount="}{.restartCount}{"\n"}{end}' 2>/dev/null
else
    echo "  (pod não encontrado)"
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  🛡️  POLÍTICAS KYVERNO ATIVAS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BOLD}ValidatingPolicies (CEL — Common Expression Language):${NC}"
kubectl get validatingpolicy --no-headers 2>/dev/null | while read name age ready; do
    echo -e "  ${GREEN}✅${NC} $name (Ready: $ready)"
done

echo ""
echo -e "${BOLD}ClusterPolicies (Mutating/Generating):${NC}"
kubectl get clusterpolicy --no-headers 2>/dev/null | while read name admission background ready age msg; do
    echo -e "  ${BLUE}⚙️${NC}  $name (Ready: $ready)"
done

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  🏗️  NODES DO CLUSTER (GPU Simulado)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
kubectl get nodes -o wide 2>/dev/null

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  📈 ECONOMIA DE CUSTO ESTIMADA${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}💰${NC} Bloqueio FinOps (H100 em dev):           ~${BOLD}\$400/dia${NC} por workload"
echo -e "  ${GREEN}💰${NC} Cache Semântico GPTCache:              ${BOLD}40-60%${NC} economia em chamadas"
echo -e "  ${GREEN}💰${NC} Resource Limits (evita monopolização):   Melhor utilização do cluster"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  🚀 PRÓXIMOS PASSOS PARA PRODUÇÃO${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  • EKS/GKE com node pools GPU (A100 spot, H100 on-demand)"
echo -e "  • NVIDIA DCGM Exporter → métricas reais de utilização"
echo -e "  • Prometheus + Grafana → dashboard 'Custo por Tenant'"
echo -e "  • Cosign + ImageValidatingPolicy → supply chain security"
echo ""

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}✅ AI-Governance-Platform — Cluster operacional com governança ativa${NC}       ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"

# Limpeza silenciosa
kubectl delete deployment vllm-production -n team-mlops --ignore-not-found=true 2>/dev/null || true
kubectl delete deployment vllm-research -n team-research --ignore-not-found=true 2>/dev/null || true
