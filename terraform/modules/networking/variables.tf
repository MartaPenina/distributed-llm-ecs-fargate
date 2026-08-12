variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

# NOTE: vpc_cidr removed — VPC is now a data source (existing_vpc_id below)

variable "existing_vpc_id" {
  description = "ID of the VPC that survived the Task 2 destroy"
  type        = string
}

variable "existing_private_db_subnet_ids" {
  description = "IDs of the private DB subnets that survived the Task 2 destroy"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

# NOTE: private_db_subnet_cidrs removed — DB subnets are now a data source