# NOTE: data.terraform_remote_state.main removed — old Task 2 state is mostly
# destroyed now, its outputs no longer exist. Values passed directly instead.

module "database" {
  source = "../modules/database"

  project_name  = var.project_name
  environment   = var.environment
  db_subnet_ids = var.db_subnet_ids
  rds_sg_ids    = [var.new_ecs_rds_sg_id]

  vpc_id                  = "vpc-0d3cae396ba16f71d"
  db_second_subnet_cidr   = "10.0.0.160/27"
  private_route_table_id  = "rtb-02ba2d443c3983002"

  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
}