output "alb_dns_name" { value = aws_lb.main.dns_name }
output "alb_zone_id"  { value = aws_lb.main.zone_id }
output "anythingllm_target_group_arn" { value = aws_lb_target_group.anythingllm.arn }

output "alb_arn_suffix" { value = aws_lb.main.arn_suffix }
output "anythingllm_target_group_arn_suffix" { value = aws_lb_target_group.anythingllm.arn_suffix }

output "ollama_internal_alb_dns_name"        { value = aws_lb.ollama_internal.dns_name }
output "ollama_target_group_arn"             { value = aws_lb_target_group.ollama.arn }
output "ollama_internal_alb_arn_suffix"      { value = aws_lb.ollama_internal.arn_suffix }
output "ollama_target_group_arn_suffix"      { value = aws_lb_target_group.ollama.arn_suffix }
