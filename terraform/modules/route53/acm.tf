# Requests a public TLS certificate for the AnythingLLM domain.
# DNS validation (not email) — AWS proves we own the domain via a
# special CNAME record it asks us to create in our own hosted zone.
resource "aws_acm_certificate" "app" {
  domain_name       = "ecs.${var.parent_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ACM tells us exactly which DNS record to create to prove ownership —
# this reads that from the certificate's validation_option and creates
# it automatically in the zone we already control.
resource "aws_route53_record" "app_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.subdomain.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# Waits until AWS actually sees that validation record and marks the
# certificate ISSUED — nothing downstream (the ALB HTTPS listener) should
# reference the cert's ARN until this resource completes.
resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for record in aws_route53_record.app_cert_validation : record.fqdn]
}
