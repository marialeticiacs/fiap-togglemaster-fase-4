variable "project_name" {
  type        = string
  description = "Nome do projeto para tagueamento de recursos"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs das subnets privadas para o EKS"
}

variable "vpc_id" {
  type        = string
  description = "ID da VPC onde o cluster e o Load Balancer serão provisionados"
}

variable "region" {
  type        = string
  default     = "us-east-2"
  description = "Região da AWS"
}