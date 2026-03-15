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