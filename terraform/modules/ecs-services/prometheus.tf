# Task Definition for Prometheus — metrics collector, scrapes itself + other services
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.project_name}-${var.environment}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                        = "1024"  # 1 vCPU
  memory                     = "2048"  # 2 GB
  execution_role_arn         = var.ecs_task_execution_role_arn
  task_role_arn               = var.ecs_task_role_arn

  volume {
    name = "prometheus-data"
    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.anythingllm_access_point_id
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "prom/prometheus:latest"
      essential = true

      portMappings = [
        { name = "prometheus-port", containerPort = 9090, protocol = "tcp" }
      ]

      mountPoints = [
        { sourceVolume = "prometheus-data", containerPath = "/prometheus" }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:9090/-/healthy || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 30
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}-prometheus"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "prometheus"
        }
      }
    }
  ])

  tags = { Name = "${var.project_name}-${var.environment}-prometheus-td" }
}

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/${var.project_name}-${var.environment}-prometheus"
  retention_in_days = 14
}

resource "aws_ecs_service" "prometheus" {
  name            = "${var.project_name}-${var.environment}-prometheus"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_app_subnet_ids
    security_groups = [var.ecs_tasks_sg_id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
    service {
      port_name      = "prometheus-port"
      discovery_name = "prometheus"

      client_alias {
        port     = 9090
        dns_name = "prometheus"
      }
    }
  }
}