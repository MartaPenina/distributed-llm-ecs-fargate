output "zone_id" {
  value = aws_route53_zone.subdomain.zone_id
}

output "name_servers" {
  description = "Add these as NS records under 'ecs' at your domain registrar (NIC.UA)"
  value       = aws_route53_zone.subdomain.name_servers
}