# ── Grafana Bastion Security Group — SSH + Grafana UI, SoftServe IPs + personal IP only ─
resource "aws_security_group" "grafana_bastion" {
  name        = "${var.project_name}-${var.environment}-grafana-bastion-sg"
  description = "SSH + Grafana UI restricted to SoftServe IP ranges and personal IP; also reachable via SSM Session Manager"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "SSH - SoftServe IP ranges only"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "Grafana UI - SoftServe IP ranges only"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP - needed for Lets Encrypt HTTP-01 challenge and redirect to HTTPS"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "HTTPS Grafana UI - SoftServe IP ranges only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-grafana-bastion-sg" }
}

# ── IAM Role — CloudWatch read + SSM Session Manager access ───
resource "aws_iam_role" "grafana_ec2" {
  name = "${var.project_name}-${var.environment}-grafana-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# Enables SSM Session Manager as an additional access method — no open port needed for this path
resource "aws_iam_role_policy_attachment" "grafana_ssm" {
  role       = aws_iam_role.grafana_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "grafana" {
  name = "${var.project_name}-${var.environment}-grafana-profile"
  role = aws_iam_role.grafana_ec2.name
}

# ── EC2 Instance — runs Grafana via systemd service baked into the Packer AMI ──
resource "aws_instance" "grafana" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.grafana_bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.grafana.name
  key_name               = var.key_pair_name

  tags = { Name = "${var.project_name}-${var.environment}-grafana-bastion" }
}

# ── Elastic IP — stable address for Grafana, survives instance replacement ──
resource "aws_eip" "grafana" {
  instance = aws_instance.grafana.id
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-${var.environment}-grafana-eip" }
}