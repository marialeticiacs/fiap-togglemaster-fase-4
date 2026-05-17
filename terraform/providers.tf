terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket = "togglemaster-terraform-state-fase-3"
    key    = "state/terraform.tfstate"
    region = "us-east-2" 
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    # ADICIONADO: Provedor Kubernetes
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    # ADICIONADO: Provedor TLS para o OIDC
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-2" 
  default_tags {
    tags = {
      Project     = "ToggleMaster"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}

# --- CONFIGURAÇÃO DO KUBERNETES (Para ServiceAccounts e OIDC) ---
provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name]
    command     = "aws"
  }
}

# --- CONFIGURAÇÃO DO HELM (ARGOCD) ---
provider "helm" {
  kubernetes {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name]
      command     = "aws"
    }
  }
}