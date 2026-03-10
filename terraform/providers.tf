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

# --- CONFIGURAÇÃO PARA O TERRAFORM ACESSAR O EKS ---

data "aws_eks_cluster" "cluster" {
  name = "togglemaster-cluster" 
}

data "aws_eks_cluster_auth" "cluster" {
  name = "togglemaster-cluster"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}