# Empty hosted zone for the ROOT domain (no "ecs." prefix). This zone
# doesn't need to serve any actual records — its only job is to make sure
# fault-lens-penina.pp.ua resolves *something* at Route53, instead of
# NIC.UA delegating to Route53 nameservers that have no zone to answer for.
#
# Why this is needed: Let's Encrypt checks CAA records at every level up
# to the root domain before issuing a certificate — even for a subdomain
# like grafana.ecs.fault-lens-penina.pp.ua, it still queries CAA for
# fault-lens-penina.pp.ua itself. Without a zone here, Route53 answers
# REFUSED (no zone found) instead of a proper "no CAA records" response,
# and certbot fails with SERVFAIL.
resource "aws_route53_zone" "root" {
  name = var.parent_domain
  tags = { Name = "${var.project_name}-${var.environment}-root-zone" }
}

output "root_zone_name_servers" {
  description = "Add these as NS records at NIC.UA for fault-lens-penina.pp.ua (the root, not the ecs. subdomain)"
  value       = aws_route53_zone.root.name_servers
}

resource "aws_route53_record" "ecs_delegation" {
  zone_id = aws_route53_zone.root.zone_id
  name    = "ecs.${var.parent_domain}"
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.subdomain.name_servers
}