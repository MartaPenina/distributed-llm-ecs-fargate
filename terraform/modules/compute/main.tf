# ECS Cluster on Fargate — logical grouping for tasks, no EC2 to manage
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  # Container Insights: enhanced per-container CPU/memory/network metrics
  # in CloudWatch — feeds directly into requirement 8 (Monitoring Configuration)
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${var.project_name}-${var.environment}-cluster" }
}

# Allows this cluster to run tasks on Fargate (serverless) and Fargate Spot
# (cheaper, interruptible — useful for non-critical/dev workloads)
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }
}