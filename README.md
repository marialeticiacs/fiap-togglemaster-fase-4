# ToggleMaster – Fase 4

Este repositório corresponde à Fase 4 do Tech Challenge da pós-graduação em DevOps & Arquitetura Cloud (FIAP).

## Visão Geral

O projeto implementa uma arquitetura de microsserviços para gerenciamento de feature flags, autenticação, avaliação, analytics e targeting, utilizando práticas modernas de infraestrutura como código, automação e orquestração em nuvem.

## Estrutura do Projeto

- **apps/**: Microsserviços principais
  - `analytics-service/` (Python)
  - `auth-service/` (Go)
  - `evaluation-service/` (Go)
  - `flag-service/` (Python)
  - `targeting-service/` (Python)
- **k8s/**: Manifests Kubernetes (deployments, ingress, autoscaling, configmaps, secrets)
- **terraform/**: Infraestrutura como código para AWS (EKS, VPC, IAM, ECR, bancos de dados)

## Tecnologias e Ferramentas

- **Docker**: Containerização dos microsserviços
- **Kubernetes (EKS)**: Orquestração e deploy na AWS
- **Terraform**: Provisionamento automatizado da infraestrutura
- **Go & Python**: Linguagens dos microsserviços
- **ArgoCD**: Preparado para GitOps e deploy contínuo

## Como Executar

1. **Provisionar Infraestrutura**
   - Configure variáveis em `terraform/`
   - Execute:
     ```
     cd terraform
     terraform init
     terraform apply
     ```
2. **Build e Deploy dos Serviços**
   - Para ambiente local: utilize os arquivos `docker-compose.yml`
   - Para produção: utilize os manifests em `k8s/` para deploy no EKS

## Fluxo de Deploy

1. Provisionamento AWS via Terraform
2. Build e push das imagens Docker para o ECR
3. Deploy dos serviços no EKS via Kubernetes
4. Configuração de ingress, autoscaling, secrets e configmaps

## Documentação dos Serviços

Cada microsserviço possui um README próprio detalhando endpoints, exemplos de uso e dependências.

## Observações

- Scripts SQL em `db/` inicializam os bancos de dados.
- Projeto pronto para integração com ArgoCD (GitOps).

## Integrantes do Grupo

- Maria Letícia
- Jeferson Rezk