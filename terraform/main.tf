module "networking" {
  source = "./modules/networking"
  project_name              = var.project_name
  environment               = var.environment
  vpc_cidr                  = var.vpc_cidr
  private_db_subnet_cidrs   = var.private_db_subnet_cidrs
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
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

module "ecs_services" {
  source = "./modules/ecs-services"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  ollama_cluster_id           = module.compute.ollama_cluster_id
  ollama_cluster_name         = module.compute.ollama_cluster_name
  anythingllm_cluster_id      = module.compute.anythingllm_cluster_id
  anythingllm_cluster_name    = module.compute.anythingllm_cluster_name
  
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.security.ecs_task_role_arn
  private_app_subnet_ids      = module.networking.private_app_subnet_ids
  ecs_tasks_sg_id             = module.security.ecs_tasks_sg_id
  ecr_repository_url          = "095083225584.dkr.ecr.eu-central-1.amazonaws.com/ollama-llm"
  efs_id                      = module.storage.efs_id
  anythingllm_access_point_id = module.storage.anythingllm_access_point_id
}

# TODO: module "monitoring" — dimensions need to reference ECS Service, not ASG
# TODO: module "route53" — needs new ALB DNS name, not bastion IP