# AWS + archive provider config for the root Task 3 stack
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
  tags = {
    Project     = "distributed-llm-ecs-fargate"   
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
}