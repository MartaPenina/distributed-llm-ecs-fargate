# Input variables for the ECS security module
variable "project_name" { type = string }
variable "environment"  { type = string }
variable "vpc_id"       { type = string }

variable "allowed_cidrs" { type = list(string) }