# ECR repository for the Ollama+model image, plus its access policy
# and lifecycle policy (auto-cleanup of old image tags)
resource "aws_ecr_repository" "ollama_llm" {
  name                 = "ollama-llm"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest"
    filter_type = "WILDCARD"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-ollama-llm"
  }
}

resource "aws_ecr_repository_policy" "ollama_llm" {
  repository = aws_ecr_repository.ollama_llm.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowTerraformSAPushPull"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::095083225584:user/terraform-sa" }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "ollama_llm" {
  repository = aws_ecr_repository.ollama_llm.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 3 tagged image versions"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 3
        }
        action = { type = "expire" }
      }
    ]
  })
}
