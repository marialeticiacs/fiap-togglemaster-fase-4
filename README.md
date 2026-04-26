# ToggleMaster Fase 

Projeto desenvolvido para o Tech Challenge da Fase 4 da pós-graduação em DevOps e Arquitetura Cloud da FIAP.

Este projeto é uma arquitetura de microsserviços para gerenciamento de recursos de feature flags, autenticação, avaliação, analytics e targeting, utilizando Docker, Kubernetes e Terraform para infraestrutura.

## Estrutura do Projeto

- **apps/**: Contém os microsserviços.
  - **analytics-service/**: Serviço de analytics (Python).
  - **auth-service/**: Serviço de autenticação (Go).
  - **evaluation-service/**: Serviço de avaliação (Go).
  - **flag-service/**: Serviço de feature flags (Python).
  - **targeting-service/**: Serviço de targeting (Python).
- **k8s/**: Manifests Kubernetes para deploy, secrets, configmaps, ingress e autoscaling.
- **terraform/**: Infraestrutura como código para AWS (EKS, VPC, IAM, ECR, bancos de dados).

## Tecnologias Utilizadas

- **Docker**: Containerização dos microsserviços.
- **Kubernetes**: Orquestração dos containers e recursos.
- **Terraform**: Provisionamento de infraestrutura na AWS.
- **Go & Python**: Linguagens dos microsserviços.

## Como Executar

1. **Infraestrutura**:
   - Configure variáveis e providers em `terraform/`.
   - Execute `terraform init` e `terraform apply` para provisionar recursos.
2. **Microsserviços**:
   - Use os arquivos `docker-compose.yml` para rodar localmente.
   - Para produção, utilize os manifests em `k8s/`.

## Fluxo de Deploy

1. Provisionamento AWS com Terraform.
2. Build e push das imagens Docker.
3. Deploy no EKS via Kubernetes.
4. Configuração de ingress, secrets e autoscaling.

## Documentação dos Serviços

Cada serviço possui um README próprio na respectiva pasta, detalhando endpoints, exemplos de uso e dependências.

## Observações

- Os scripts SQL em `db/` inicializam os bancos de dados.
- O projeto está preparado para integração com ArgoCD.