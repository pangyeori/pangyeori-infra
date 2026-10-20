# ---- ECR: 이미지는 CI가 푸시한다 ----
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project}/backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.ecr_untagged_expire_days} day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.ecr_untagged_expire_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the latest ${var.ecr_max_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_max_images
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ---- Secrets Manager: 값을 Terraform 으로 넣으면 state 에 평문이 남으므로 껍데기만 관리한다 ----
resource "aws_secretsmanager_secret" "app" {
  name = "${var.environment}/${var.project}/secret"
}
