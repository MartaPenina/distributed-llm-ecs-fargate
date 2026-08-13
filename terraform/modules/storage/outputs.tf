# Exposes access point ARNs for Task Definitions to reference as volume mounts
output "efs_id"                    { value = aws_efs_file_system.main.id }
output "anythingllm_access_point_id" { value = aws_efs_access_point.anythingllm.id }