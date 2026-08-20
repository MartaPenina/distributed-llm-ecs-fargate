# Two separate clusters — Ollama (private-only) and AnythingLLM (public-facing via ALB)

resource "aws_ecs_cluster" "ollama" {
  name = "${var.project_name}-${var.environment}-ollama-cluster"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  tags = { Name = "${var.project_name}-${var.environment}-ollama-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "ollama" {
  cluster_name        = aws_ecs_cluster.ollama.name
  capacity_providers  = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }
}

resource "aws_ecs_cluster" "anythingllm" {
  name = "${var.project_name}-${var.environment}-anythingllm-cluster"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  tags = { Name = "${var.project_name}-${var.environment}-anythingllm-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "anythingllm" {
  cluster_name       = aws_ecs_cluster.anythingllm.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }
}