# Values exposed for other Terraform projects/modules to reference
# (e.g. the main ECS stack will need this URL for task definitions)
output "repository_url" {
  value = aws_ecr_repository.ollama_llm.repository_url
}