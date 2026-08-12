# Exposes service names for later use (ALB target groups in requirement 6)
output "ollama_service_name"      { value = aws_ecs_service.ollama.name }
output "anythingllm_service_name" { value = aws_ecs_service.anythingllm.name }
output "prometheus_service_name"  { value = aws_ecs_service.prometheus.name }

output "service_connect_namespace_arn" { value = aws_service_discovery_http_namespace.main.arn }