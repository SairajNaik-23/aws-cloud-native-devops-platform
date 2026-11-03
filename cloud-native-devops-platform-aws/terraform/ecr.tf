# Private Docker image registry. Jenkins pushes images here, EKS pulls from here.

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # allows `terraform destroy` even if images exist (dev only)

  image_scanning_configuration {
    scan_on_push = true # free vulnerability scan on every push
  }
}

# Keep only the last 10 images to save storage cost
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
