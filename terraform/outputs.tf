# Root-level outputs — currently exposes only networking module values
# (bastion/asg outputs removed since compute module is disabled)
output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.networking.private_db_subnet_ids
}

output "private_route_table_id" {
  value = module.networking.private_route_table_id
}