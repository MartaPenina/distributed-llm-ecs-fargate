# Exposes cluster identifiers for the future Task Definition/Service module
output "cluster_id"   { value = aws_ecs_cluster.main.id }
output "cluster_name" { value = aws_ecs_cluster.main.name }
output "cluster_arn"  { value = aws_ecs_cluster.main.arn }