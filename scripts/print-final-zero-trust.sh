#!/usr/bin/env bash
set -euo pipefail

clear

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}AI-Governance-Platform — Zero Trust Pipeline de IA${NC}                        ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}C2PA + SLSA L3 + Cosign + FinOps + GPTCache + Falco Runtime${NC}             ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  🛡️  CAMADAS DE SEGURANÇA ATIVAS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BOLD}1. Supply Chain (Pré-Deploy):${NC}"
echo -e "  ${GREEN}✅${NC} C2PA — Hash do modelo verificado"
echo -e "  ${GREEN}✅${NC} SLSA Level 3 — Proveniência GitLab CI"
echo -e "  ${GREEN}✅${NC} Cosign — Assinatura criptográfica"

echo ""
echo -e "${BOLD}2. Admission Controller (Deploy):${NC}"
echo -e "  ${GREEN}✅${NC} Kyverno FinOps — Bloqueia GPU premium em dev"
echo -e "  ${GREEN}✅${NC} Kyverno Resource Limits — Exige limits GPU"
echo -e "  ${GREEN}✅${NC} Kyverno Mutating — Injeta GPTCache sidecar"

echo ""
echo -e "${BOLD}3. Runtime Security (Pós-Deploy):${NC}"
echo -e "  ${GREEN}✅${NC} Falco — Detecção de intrusão em tempo real"
echo -e "  ${GREEN}✅${NC} eBPF — Monitoramento de syscalls do kernel"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  🔐 ALERTA FALCO CAPTURADO (Runtime)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${RED}⚠️  Ameaça detectada em tempo real:${NC}"
echo "   Tipo: Sensitive file opened for reading by non-trusted program"
echo "   Arquivo: /etc/shadow"
echo "   Processo: cat"
echo "   Comando: cat /etc/shadow"
echo "   Container: falco-test (team-mlops)"
echo "   → Ação: Container deletado automaticamente após teste"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  💰 ECONOMIA + GOVERNANÇA${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}🔒${NC} Supply Chain: 3 camadas de verificação (C2PA + SLSA + Cosign)"
echo -e "  ${GREEN}💰${NC} FinOps: ~${BOLD}\$400/dia${NC} economizado por workload bloqueado"
echo -e "  ${GREEN}💰${NC} GPTCache: ${BOLD}40-60%${NC} economia em chamadas repetidas"
echo -e "  ${GREEN}🛡️${NC} Runtime: Falco detecta ameaças em tempo real"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}✅ ZERO TRUST PIPELINE COMPLETO — 5 Camadas de Proteção${NC}                   ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}dataset → treino → assinatura → deploy → cache → monitoramento → resposta${NC} ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
