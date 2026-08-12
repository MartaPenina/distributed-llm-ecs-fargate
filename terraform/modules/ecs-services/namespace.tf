# Private DNS namespace for ECS Service Connect — lets services find each
# other by name (e.g. "ollama") instead of hardcoded IPs, within the VPC only
resource "aws_service_discovery_http_namespace" "main" {
  name        = "${var.project_name}-${var.environment}.local"
  description = "Service Connect namespace for internal service discovery"
}