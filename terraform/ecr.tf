locals {
  microservices = ["auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service"]
}
resource "aws_ecr_repository" "repos" {
  for_each             = toset(local.microservices)
  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}