# Task Definition for AnythingLLM — web frontend for LLM interaction
resource "aws_ecs_task_definition" "anythingllm" {
  family                   = "${var.project_name}-${var.environment}-anythingllm"
  requires_compatibilities = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                        = "2048"   # 2 vCPU
  memory                     = "4096"   # 4 GB
  execution_role_arn         = var.ecs_task_execution_role_arn
  task_role_arn               = var.ecs_task_role_arn

  # EFS volume for persistent storage (chat history/settings survive task restarts)
  volume {
    name = "anythingllm-storage"

    efs_volume_configuration {
      file_system_id          = var.efs_id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = var.anythingllm_access_point_id
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "anythingllm"
      image     = "mintplexlabs/anythingllm:pg"
      essential = true

      portMappings = [
        {
          name          = "anythingllm-port"
          containerPort = 3001
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "anythingllm-storage"
          containerPath = "/app/server/storage"
        }
      ]

      # secrets pulled from SSM at task start — never hardcoded in the image or env
      secrets = [
        { name = "DATABASE_URL",  valueFrom = "/distributed-llm-ecs-fargate/dev/database_url" },
        { name = "AUTH_TOKEN",     valueFrom = "/distributed-llm-ecs-fargate/dev/anythingllm_password" },
        { name = "JWT_SECRET",     valueFrom = "/distributed-llm-ecs-fargate/dev/anythingllm_jwt_secret" },
        { name = "SIG_KEY",  valueFrom = "/distributed-llm-ecs-fargate/dev/anythingllm_sig_key" },
        { name = "SIG_SALT", valueFrom = "/distributed-llm-ecs-fargate/dev/anythingllm_sig_salt" }
      ]

      environment = [
        { name = "STORAGE_DIR", value = "/app/server/storage" }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3001/ || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 30
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}-anythingllm"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "anythingllm"
        }
      }
    }
  ])

  tags = { Name = "${var.project_name}-${var.environment}-anythingllm-td" }
}

resource "aws_cloudwatch_log_group" "anythingllm" {
  name              = "/ecs/${var.project_name}-${var.environment}-anythingllm"
  retention_in_days = 14
}

resource "aws_ecs_service" "anythingllm" {
  name            = "${var.project_name}-${var.environment}-anythingllm"
  cluster = var.anythingllm_cluster_id
  task_definition = aws_ecs_task_definition.anythingllm.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_app_subnet_ids
    security_groups = [var.ecs_tasks_sg_id]
  }

  load_balancer {
    target_group_arn = var.anythingllm_target_group_arn
    container_name    = "anythingllm"
    container_port     = 3001
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn

    service {
      port_name      = "anythingllm-port"
      discovery_name = "anythingllm"

      client_alias {
        port     = 3001
        dns_name = "anythingllm"
      }
    }
  }

}