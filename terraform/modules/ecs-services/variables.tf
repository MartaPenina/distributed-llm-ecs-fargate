# Input variables for the ECS services module (Task Definitions + Services)
variable "project_name" { type = string }
variable "environment"  { type = string }
variable "aws_region"   { type = string }

variable "ecs_cluster_id"                { type = string }
variable "ecs_task_execution_role_arn"   { type = string }
variable "ecs_task_role_arn"             { type = string }
variable "private_app_subnet_ids"        { type = list(string) }
variable "ecs_tasks_sg_id"               { type = string }
variable "ecr_repository_url"            { type = string }

variable "efs_id"                        { type = string }
variable "prometheus_access_point_id"    { type = string }
variable "anythingllm_access_point_id"   { type = string }

variable "ecs_cluster_name" { type = string }