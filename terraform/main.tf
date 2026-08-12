# Root module — wires together the networking module now; other modules
# (security/compute/monitoring/route53) are commented out until rewritten for ECS
data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket  = "distributed-llm-aws-tf-state-v2"
    key     = "distributed-llm-aws/rds/terraform.tfstate"
    region  = "eu-central-1"
    profile = "distributed-llm-aws"
  }
}

module "networking" {
  source = "./modules/networking"

  project_name                   = var.project_name
  environment                    = var.environment
  existing_vpc_id                = var.existing_vpc_id
  existing_private_db_subnet_ids = var.existing_private_db_subnet_ids
  public_subnet_cidrs            = var.public_subnet_cidrs
  private_app_subnet_cidrs       = var.private_app_subnet_cidrs
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
}

module "compute" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment
}

module "storage" {
  source = "./modules/storage"

  project_name           = var.project_name
  environment             = var.environment
  private_app_subnet_ids  = module.networking.private_app_subnet_ids
  efs_sg_id               = module.security.efs_sg_id
}
# TODO: module "monitoring" — dimensions need to reference ECS Service, not ASG
# TODO: module "route53" — needs new ALB DNS name, not bastion IP