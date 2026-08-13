output "ollama_cluster_id"        { value = aws_ecs_cluster.ollama.id }
output "ollama_cluster_name"      { value = aws_ecs_cluster.ollama.name }
output "anythingllm_cluster_id"   { value = aws_ecs_cluster.anythingllm.id }
output "anythingllm_cluster_name" { value = aws_ecs_cluster.anythingllm.name }