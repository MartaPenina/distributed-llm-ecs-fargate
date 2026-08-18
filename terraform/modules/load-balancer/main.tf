# Public-facing ALB — entry point for all external traffic
resource "aws_lb" "main" {
  name               = "${var.environment}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-${var.environment}-alb" }
}

# Target group for AnythingLLM (Web Service) — main entry point for users
resource "aws_lb_target_group" "anythingllm" {
  name        = "${var.environment}-allm-tg"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # required for awsvpc-mode ECS tasks

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 10
  }

  tags = { Name = "${var.project_name}-${var.environment}-anythingllm-tg" }
}

# HTTP listener — redirects everything to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = var.acm_certificate_arn != "" ? "redirect" : "forward"
    target_group_arn = var.acm_certificate_arn != "" ? null : aws_lb_target_group.anythingllm.arn

    dynamic "redirect" {
      for_each = var.acm_certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# HTTPS listener — path-based routing to services
resource "aws_lb_listener" "https" {
  count = var.acm_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.anythingllm.arn
  }
}

# ── Internal ALB — balances traffic to Ollama tasks, not reachable from
# the internet (no public IP, lives in private subnets). AnythingLLM talks
# to this instead of a single Ollama task directly, so multiple Ollama
# replicas (from auto-scaling) get load-balanced traffic with proper
# per-target health checks.
resource "aws_lb" "ollama_internal" {
  name               = "${var.environment}-ollama-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.ecs_tasks_sg_id]
  subnets            = var.private_app_subnet_ids
  tags = { Name = "${var.project_name}-${var.environment}-ollama-internal-alb" }
}

# Target group for Ollama tasks — port 11434 is Ollama's own API port
resource "aws_lb_target_group" "ollama" {
  name        = "${var.environment}-ollama-tg"
  port        = 11434
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # required for awsvpc-mode ECS tasks, same as anythingllm

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 10
  }

  tags = { Name = "${var.project_name}-${var.environment}-ollama-tg" }
}

# Internal listener — plain HTTP is fine here since this ALB never leaves
# the VPC; there's no public exposure to protect against
resource "aws_lb_listener" "ollama_internal" {
  load_balancer_arn = aws_lb.ollama_internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ollama.arn
  }
}
