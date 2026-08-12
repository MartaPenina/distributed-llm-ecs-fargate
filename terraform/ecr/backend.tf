# Where Terraform stores state for this module (ECR only — separate from
# the main infra stack so ECR survives nightly destroy/apply cycles)
terraform {
  backend "s3" {
    bucket       = "distributed-llm-ecs-fargate-tf-state"
    key          = "distributed-llm-ecs-fargate/ecr/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
    profile      = "distributed-llm-aws"
  }
}