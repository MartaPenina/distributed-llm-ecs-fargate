# Input variables for the ECR module (region, profile, naming)
variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "aws_profile" {
  type    = string
  default = "distributed-llm-aws"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "distributed-llm-ecs-fargate"
}