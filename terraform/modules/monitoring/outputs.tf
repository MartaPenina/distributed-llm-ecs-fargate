output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "grafana_public_ip" {
  value = aws_eip.grafana.public_ip
}