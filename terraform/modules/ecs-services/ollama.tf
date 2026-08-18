# Task Definition for Ollama — the LLM inference service, 8 vCPU/16GB per
# resource testing done earlier (confirmed via local docker --cpus/--memory tests)
resource "aws_ecs_task_definition" "ollama" {
  family                   = "${var.project_name}-${var.environment}-ollama"
  requires_compatibilities = ["FARGATE"]
  network_mode              = "awsvpc"  # required for Fargate — each task gets its own ENI
  cpu                        = "8192"    # 8 vCPU
  memory                     = "16384"   # 16 GB
  execution_role_arn         = var.ecs_task_execution_role_arn
  task_role_arn               = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "ollama"
      image     = "${var.ecr_repository_url}:v6"
      essential = true

      portMappings = [
        {
          name          = "ollama-port"
          containerPort = 11434
          protocol      = "tcp"
        }
      ]
      
      # health check: Ollama responds on / when ready
      healthCheck = {
        command     = ["CMD-SHELL", "ollama list || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 60  # give the model time to load before first check counts
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}-ollama"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ollama"
        }
      }
    }
  ])

  tags = { Name = "${var.project_name}-${var.environment}-ollama-td" }
}

# CloudWatch Log Group — must exist before the task starts writing logs to it
resource "aws_cloudwatch_log_group" "ollama" {
  name              = "/ecs/${var.project_name}-${var.environment}-ollama"
  retention_in_days = 14
}

# ECS Service — keeps 1 Ollama task running, restarts it if it dies
resource "aws_ecs_service" "ollama" {
  name            = "${var.project_name}-${var.environment}-ollama"
  cluster = var.ollama_cluster_id
  task_definition = aws_ecs_task_definition.ollama.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_app_subnet_ids
    security_groups = [var.ecs_tasks_sg_id]
  }

  # ECS Service Connect — gives this service an internal DNS name other
  # services can use to reach it (e.g. "ollama.internal") without hardcoded IPs
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn

    service {
      port_name      = "ollama-port"
      discovery_name = "ollama"

      client_alias {
        port     = 11434
        dns_name = "ollama"
      }
    }
  }

  # Registers Ollama tasks with the internal ALB's target group — this is
  # what actually makes the internal load balancer aware of this task,
  # same pattern as anythingllm's load_balancer block for the public ALB
  load_balancer {
    target_group_arn = var.ollama_target_group_arn
    container_name    = "ollama"
    container_port     = 11434
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  # named so Service Connect knows which container/port to expose
  # (must match a portMapping name in the task definition — will add below)
}