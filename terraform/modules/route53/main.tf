# New hosted zone for the Task 3 subdomain — separate from the old
# fault-lens-penina.pp.ua zone (destroyed), delegated as a subdomain
resource "aws_route53_zone" "subdomain" {
  name = "ecs.${var.parent_domain}"

  tags = { Name = "${var.project_name}-${var.environment}-ecs-zone" }
}

# A record (alias) pointing the subdomain to the ALB — no static IP needed,
# ALB's IP can change, alias always resolves to the current one automatically
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.subdomain.zone_id
  name    = "ecs.${var.parent_domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# A record for Grafana bastion — points at its stable Elastic IP
resource "aws_route53_record" "grafana" {
  zone_id = aws_route53_zone.subdomain.zone_id
  name    = "grafana.ecs.${var.parent_domain}"
  type    = "A"
  ttl     = 300
  records = [var.grafana_public_ip]
}