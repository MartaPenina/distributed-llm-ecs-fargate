# Input variables for the EFS storage module
variable "project_name"            { type = string }
variable "environment"             { type = string }
variable "private_app_subnet_ids"  { type = list(string) }
variable "efs_sg_id"               { type = string }