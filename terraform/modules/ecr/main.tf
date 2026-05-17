resource "aws_ecr_repository" "repos" {
  for_each = toset([
    "auth-service",
    "flag-service",
    "evaluation-service",
    "targeting-service",
    "analytics-service"
  ])

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}