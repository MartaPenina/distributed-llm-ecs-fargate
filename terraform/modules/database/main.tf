resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = concat(var.db_subnet_ids, [aws_subnet.db_second_az.id])

  tags = { Name = "${var.project_name}-${var.environment}-db-subnet-group" }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Name = "${var.project_name}-${var.environment}-rds-monitoring-role" }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-${var.environment}-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.rds_sg_ids

  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"
  deletion_protection       = true
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  tags = { Name = "${var.project_name}-${var.environment}-postgres" }

  lifecycle {
    prevent_destroy = true
  }
}

# Second DB subnet (eu-central-1b) — RDS subnet groups require 2+ AZ coverage,
# even for single-AZ instances. Only one DB subnet survived the Task 2 destroy.
resource "aws_subnet" "db_second_az" {
  vpc_id            = var.vpc_id
  cidr_block        = var.db_second_subnet_cidr
  availability_zone = "eu-central-1b"

  tags = { Name = "${var.project_name}-${var.environment}-private-db-2" }
}

resource "aws_route_table_association" "db_second_az" {
  subnet_id      = aws_subnet.db_second_az.id
  route_table_id = var.private_route_table_id
}