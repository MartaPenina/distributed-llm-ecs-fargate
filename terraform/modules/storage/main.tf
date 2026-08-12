# EFS filesystem shared by Prometheus and AnythingLLM, each isolated via its own access point
resource "aws_efs_file_system" "main" {
  creation_token   = "${var.project_name}-${var.environment}-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = { Name = "${var.project_name}-${var.environment}-efs" }
}

# Mount targets — one per private subnet/AZ, so tasks in either AZ can reach EFS
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_app_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_app_subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

# Access point for Prometheus — isolated directory + POSIX permissions
resource "aws_efs_access_point" "prometheus" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    uid = 65534  # nobody user — matches Prometheus container's default non-root user
    gid = 65534
  }

  root_directory {
    path = "/prometheus-data"
    creation_info {
      owner_uid   = 65534
      owner_gid   = 65534
      permissions = "755"
    }
  }

  tags = { Name = "${var.project_name}-${var.environment}-prometheus-ap" }
}

# Access point for AnythingLLM storage
resource "aws_efs_access_point" "anythingllm" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/anythingllm-storage"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  tags = { Name = "${var.project_name}-${var.environment}-anythingllm-ap" }
}

# Backup — AWS Backup plan for EFS (requirement: "proper backup mechanisms")
resource "aws_backup_vault" "efs" {
  name = "${var.project_name}-${var.environment}-efs-backup-vault"
}

resource "aws_backup_plan" "efs" {
  name = "${var.project_name}-${var.environment}-efs-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.efs.name
    schedule          = "cron(0 3 * * ? *)"  # daily at 3 AM UTC

    lifecycle {
      delete_after = 30  # keep backups for 30 days
    }
  }
}

resource "aws_backup_selection" "efs" {
  name         = "${var.project_name}-${var.environment}-backup-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.efs.id

  resources = [aws_efs_file_system.main.arn]
}

resource "aws_iam_role" "backup" {
  name = "${var.project_name}-${var.environment}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}