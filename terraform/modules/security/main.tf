# Security groups (ALB -> ECS tasks -> RDS trust chain) and IAM roles for ECS

# ── ALB Security Group — public-facing ───────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS from allowed IPs only, forward to ECS tasks only"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "HTTP - SoftServe IP ranges only"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "HTTPS - SoftServe IP ranges only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-alb-sg" }
}

# ── ECS Tasks Security Group — only reachable from ALB ────────
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Any container port, but only from the ALB"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow traffic between ECS tasks, e.g. AnythingLLM to Ollama"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-ecs-tasks-sg" }
}

# ── RDS Security Group — only reachable from ECS tasks ────────
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow PostgreSQL from ECS tasks only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
    description     = "PostgreSQL from ECS tasks only"
  }

  tags = { Name = "${var.project_name}-${var.environment}-rds-sg" }
}

# ── ECS Task Execution Role — used by ECS agent (pull image, write logs) ──
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# AWS managed policy: ECR pull + CloudWatch Logs write — standard for any ECS task
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Execution Role needs explicit EFS permissions to mount access points —
# AmazonECSTaskExecutionRolePolicy alone doesn't cover this
resource "aws_iam_role_policy" "ecs_task_execution_efs" {
  name = "${var.project_name}-${var.environment}-ecs-execution-efs-policy"
  role = aws_iam_role.ecs_task_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:DescribeMountTargets"
      ]
      Resource = "*"
    }]
  })
}

# ── ECS Task Role — used by the app code inside the container ─
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# App-level access: read secrets (DB password, Discord webhook) from SSM
resource "aws_iam_role_policy" "ecs_task_ssm" {
  name = "${var.project_name}-${var.environment}-ecs-task-ssm-policy"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}/*"
    }]
  })
}

# ── EFS Security Group — only reachable from ECS tasks (NFS port) ─────
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-${var.environment}-efs-sg"
  description = "Allow NFS from ECS tasks only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
    description     = "NFS from ECS tasks only"
  }

  tags = { Name = "${var.project_name}-${var.environment}-efs-sg" }
}

# Task Execution Role needs SSM read access to pull secrets into containers at startup
resource "aws_iam_role_policy" "ecs_task_execution_ssm" {
  name = "${var.project_name}-${var.environment}-ecs-execution-ssm-policy"
  role = aws_iam_role.ecs_task_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters", "ssm:GetParameter"]
      Resource = ["arn:aws:ssm:*:*:parameter/${var.project_name}/*"]
    }]
  })
}