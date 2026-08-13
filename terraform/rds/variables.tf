variable "aws_region" { type = string }
variable "aws_profile" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }

variable "db_name" { type = string }
variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_instance_class" { type = string }

variable "new_ecs_rds_sg_id" {
  description = "New RDS SG from the ECS Fargate stack, allows access from ECS tasks"
  type        = string
}

variable "db_subnet_ids" {
  type = list(string)
}