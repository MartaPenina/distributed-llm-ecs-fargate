variable "project_name"        { type = string }
variable "environment"         { type = string }
variable "vpc_id"               { type = string }
variable "public_subnet_ids"    { type = list(string) }
variable "alb_sg_id"             { type = string }
variable "acm_certificate_arn" {
  type    = string
  default = ""
}

variable "private_app_subnet_ids" { type = list(string) }
variable "ecs_tasks_sg_id"        { type = string }