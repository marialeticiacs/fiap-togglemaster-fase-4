variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Nome do projeto para as tags"
  type        = string
}

variable "region" {
  description = "Região da AWS"
  type        = string
}