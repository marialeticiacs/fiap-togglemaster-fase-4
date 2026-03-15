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
    # NOVO: Provedor do Helm para instalar o ArgoCD
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
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

# --- CONFIGURAÇÃO DO HELM (ARGOCD) ---
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}