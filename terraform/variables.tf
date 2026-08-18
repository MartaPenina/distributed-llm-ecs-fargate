# Root-level input variables for the main Task 3 infra stack
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "distributed-llm-aws"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for naming and tagging"
  type        = string
  default     = "distributed-llm-ecs-fargate"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "private_db_subnet_cidrs" {
  description = "Private DB subnet CIDRs (for RDS, across 2 AZ)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (one per AZ)"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDRs (for ECS Fargate tasks)"
  type        = list(string)
}

variable "alert_email" {
  description = "Email address to receive CloudWatch/Grafana alert notifications"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access to Grafana bastion"
  type        = string
}

variable "grafana_allowed_cidrs" {
  description = "SoftServe IP ranges + personal IP allowed to access Grafana bastion and ALB"
  type        = list(string)
}

variable "grafana_ami_id" {
  description = "Custom Packer-built AMI ID for the Grafana bastion host"
  type        = string
}

variable "parent_domain" {
  description = "Parent domain registered at NIC.UA"
  type        = string
}