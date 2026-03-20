# 1. Create the Private ECR Repository
resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.project_name}-${var.environment}-repo"
  
  # Allow overwriting tags like 'latest' in dev/staging.
  image_tag_mutability = var.environment == "live" ? "IMMUTABLE" : "MUTABLE"
  
  # Allow Terraform to destroy this repository in dev/staging even if it has images inside
  force_delete = var.environment != "live"

  # Automatically scan your Docker images for security vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-repo"
    Environment = var.environment
  }
}

# 2. Add a Lifecycle Policy to save storage costs
resource "aws_ecr_lifecycle_policy" "repo_policy" {
  repository = aws_ecr_repository.app_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}