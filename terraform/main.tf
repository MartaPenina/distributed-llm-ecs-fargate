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

  project_name  = var.project_name
  environment   = var.environment
  vpc_id        = module.networking.vpc_id
  allowed_cidrs = var.grafana_allowed_cidrs
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
  anythingllm_target_group_arn = module.load_balancer.anythingllm_target_group_arn
  alb_arn_suffix                       = module.load_balancer.alb_arn_suffix
  anythingllm_target_group_arn_suffix  = module.load_balancer.anythingllm_target_group_arn_suffix
  ollama_target_group_arn = module.load_balancer.ollama_target_group_arn
}

module "load_balancer" {
  source = "./modules/load-balancer"
  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  ecs_tasks_sg_id         = module.security.ecs_tasks_sg_id
  acm_certificate_arn = module.route53.certificate_arn
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name      = var.project_name
  environment       = var.environment
  alert_email       = var.alert_email
  vpc_id            = module.networking.vpc_id
  public_subnet_id  = module.networking.public_subnet_ids[0]
  allowed_cidrs     = var.grafana_allowed_cidrs
  key_pair_name     = var.key_pair_name
  ami_id = var.grafana_ami_id
  db_instance_id = "distributed-llm-ecs-fargate-dev-postgres"
  alb_arn_suffix = module.load_balancer.alb_arn_suffix
  anythingllm_target_group_arn_suffix = module.load_balancer.anythingllm_target_group_arn_suffix
}

module "route53" {
  source = "./modules/route53"

  project_name  = var.project_name
  environment   = var.environment
  parent_domain = var.parent_domain
  alb_dns_name  = module.load_balancer.alb_dns_name
  alb_zone_id   = module.load_balancer.alb_zone_id
  grafana_public_ip = module.monitoring.grafana_public_ip
}