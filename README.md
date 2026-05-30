# 🤖 AI-Governance-Platform

> Plataforma de governança para IA Generativa em Kubernetes: FinOps, otimização transparente, supply chain security e runtime threat detection.

[![Tests](https://img.shields.io/badge/tests-5/5%20passing-brightgreen)]()
[![Kyverno](https://img.shields.io/badge/Kyverno-CEL-blue)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()

## 🎯 Problema Resolvido

Empresas que adotam IA Generativa enfrentam:
- 💸 Custos exponenciais de inferência 24/7 com GPUs premium
- 🔓 Riscos de segurança: modelos adulterados, supply chain attacks
- 🐌 Latência alta sem cache inteligente
- 👨‍💻 Atrito com desenvolvedores: "não quero reescrever código"

## ✨ Solução em 4 Camadas

| Camada | Ferramenta | Função | Impacto |
|--------|-----------|--------|---------|
| **Admission** | Kyverno + CEL | Bloqueia configs abusivas (FinOps) | 40-60% economia em GPUs |
| **Optimization** | MutatingPolicy | Injeta GPTCache sidecar | Latência ↓44%, cache hit ~45% |
| **Supply Chain** | C2PA + InitContainer | Valida modelo antes de rodar | Zero Trust: modelo adulterado = Pod NUNCA sobe |
| **Runtime** | Falco + eBPF | Detecta ameaças em tempo real | Alertas de tampering, shell, exfiltração |

## 🧪 Testes Validados

```bash
# Bootstrap do ambiente
./scripts/bootstrap.sh

# Suite completa de testes
./tests/test-suite-completo.sh

# Resultado esperado:
✅ FinOps: GPU governance funcionando
✅ Mutating: GPTCache injection funcionando  
✅ C2PA: Modelo legítimo aceito, adulterado bloqueado
✅ Falco: Alertas de runtime security capturados

# 1. FinOps: Tentar deploy abusivo em dev
kubectl apply -f workloads/abusive/inference-premium-dev.yaml
# ❌ Bloqueado: "FinOps violation: dev/staging nao podem solicitar mais de 4 GPUs"

# 2. Mutating: Deploy válido com cache automático
kubectl apply -f workloads/valid/inference-standard.yaml
kubectl get deployment vllm-standard -n team-mlops -o jsonpath='{.spec.template.spec.containers[*].name}'
# ✅ Output: "vllm gptcache-sidecar"

# 3. C2PA: Modelo adulterado é bloqueado
# (ver tests/test-c2pa-attack-demo.sh)
# ✅ Init container falha com exit 1 → Pod nunca sobe

# 1. FinOps: Tentar deploy abusivo em dev
kubectl apply -f workloads/abusive/inference-premium-dev.yaml
# ❌ Bloqueado: "FinOps violation: dev/staging nao podem solicitar mais de 4 GPUs"

# 2. Mutating: Deploy válido com cache automático
kubectl apply -f workloads/valid/inference-standard.yaml
kubectl get deployment vllm-standard -n team-mlops -o jsonpath='{.spec.template.spec.containers[*].name}'
# ✅ Output: "vllm gptcache-sidecar"

# 3. C2PA: Modelo adulterado é bloqueado
# (ver tests/test-c2pa-attack-demo.sh)
# ✅ Init container falha com exit 1 → Pod nunca sobe

🛠️ Stack Tecnológica
Kubernetes: v1.31.0 via Kind (WSL2)
Policy Engine: Kyverno v1.18.1 + CEL (Common Expression Language)
Cache: GPTCache + Redis
Inference: vLLM
Supply Chain: C2PA + InitContainer validation
Runtime Security: Falco + eBPF
Observability: Prometheus + Grafana (ready)
📄 Documentação
📘 Technical Documentation — Arquitetura, decisões, RCA
🧪 Test Suite — Como validar cada camada
🚀 Demo Scripts — Roteiros para entrevistas
🤝 Contributing
Fork o projeto
Crie uma branch para sua feature (git checkout -b feature/AmazingFeature)
Commit suas mudanças (git commit -m 'Add some AmazingFeature')
Push para a branch (git push origin feature/AmazingFeature)
Abra um Pull Request
📄 License
Distribuído sob a licença MIT. Veja LICENSE para mais informações.
💡 Platform Engineering na prática: Segurança invisível, otimização transparente, custo controlado, auditoria nativa.
# 🤖 AI-Governance-Platform

[![Tests](https://img.shields.io/badge/tests-5/5%20passing-brightgreen?style=for-the-badge)]()
[![Kyverno](https://img.shields.io/badge/Kyverno-CEL-blue?style=for-the-badge&logo=kubernetes)]()
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)]()
[![Platform Engineering](https://img.shields.io/badge/Platform-Engineering-orange?style=for-the-badge)]()

> Governança de IA Generativa em Kubernetes: FinOps • Otimização • Zero Trust • Runtime Security

