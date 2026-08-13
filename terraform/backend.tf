terraform {
  backend "s3" {
    bucket       = "distributed-llm-ecs-fargate-tf-state2"
    key          = "distributed-llm-ecs-fargate/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
    profile      = "distributed-llm-aws"
  }
}