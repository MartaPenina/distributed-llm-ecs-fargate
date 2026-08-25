variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "Email address to receive CloudWatch/Grafana alert notifications"
}

# TODO: rework for ECS/RDS/ALB dimensions (Task3) — commented out along with
# the alarms in main.tf that used to reference these Task2-era variables
/*
variable "asg_name" {
  type        = string
  description = "Auto Scaling Group name for CloudWatch alarm dimensions"
}
*/

variable "cloudwatch_alarms" {
  description = "Map of additional CloudWatch alarms (EC2 mem/disk, RDS, ALB)"
  type = map(object({
    metric_name         = string
    namespace           = string
    statistic           = string
    period              = number
    evaluation_periods  = number
    threshold           = number
    comparison_operator = string
    dimensions          = map(string)
    alarm_description   = string
  }))
  default = {}
}

/*
variable "db_instance_id" {
  description = "RDS instance identifier for CloudWatch alarm dimensions"
  type        = string
}

variable "ollama_internal_alb_arn_suffix" {
  description = "Internal Ollama ALB arn_suffix for CloudWatch alarm dimensions"
  type        = string
}

variable "ollama_internal_target_group_arn_suffix" {
  description = "Internal Ollama ALB target group arn_suffix for CloudWatch alarm dimensions"
  type        = string
}
*/

variable "vpc_id"          { type = string }
variable "public_subnet_id" { type = string }
variable "allowed_cidrs"    { type = list(string) }
variable "key_pair_name"    { type = string }

variable "ami_id" { type = string }
variable "db_instance_id" { type = string }
variable "alb_arn_suffix" { type = string }
variable "anythingllm_target_group_arn_suffix" { type = string }
