# SNS topic for alert notifications — CloudWatch/Grafana alarms publish here,
# subscribers (email + Discord via Lambda) receive them.
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Reworked for Task3 (ECS Fargate architecture) — the original Task2 alarms
# referenced an ASG and an internal Ollama ALB that no longer exist. RDS
# alarms are unchanged (same database). ALB alarms now point at the public
# AnythingLLM ALB, since Ollama has no ALB in this architecture (private only).
locals {
  monitoring_alarms = {
    "${var.project_name}-${var.environment}-db-high-cpu" = {
      metric_name         = "CPUUtilization"
      namespace           = "AWS/RDS"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 2
      threshold           = 80
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { DBInstanceIdentifier = var.db_instance_id }
      alarm_description   = "RDS CPU usage above 80% for 10 minutes"
    }
    "${var.project_name}-${var.environment}-db-low-storage" = {
      metric_name         = "FreeStorageSpace"
      namespace           = "AWS/RDS"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 2
      threshold           = 2000000000 # 2 GB in bytes
      comparison_operator = "LessThanThreshold"
      dimensions          = { DBInstanceIdentifier = var.db_instance_id }
      alarm_description   = "RDS free storage below 2GB"
    }
    "${var.project_name}-${var.environment}-db-low-memory" = {
      metric_name         = "FreeableMemory"
      namespace           = "AWS/RDS"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 2
      threshold           = 200000000 # 200 MB in bytes
      comparison_operator = "LessThanThreshold"
      dimensions          = { DBInstanceIdentifier = var.db_instance_id }
      alarm_description   = "RDS freeable memory below 200MB"
    }
    "${var.project_name}-${var.environment}-alb-low-healthy-hosts" = {
      metric_name         = "HealthyHostCount"
      namespace           = "AWS/ApplicationELB"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 2
      threshold           = 1
      comparison_operator = "LessThanThreshold"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
        TargetGroup  = var.anythingllm_target_group_arn_suffix
      }
      alarm_description = "Fewer than 1 healthy host behind the AnythingLLM ALB target group"
    }
    "${var.project_name}-${var.environment}-alb-high-4xx-errors" = {
      metric_name         = "HTTPCode_Target_4XX_Count"
      namespace           = "AWS/ApplicationELB"
      statistic           = "Sum"
      period              = 300
      evaluation_periods  = 2
      threshold           = 10
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
      alarm_description = "More than 10 4XX errors in 5 minutes"
    }
    "${var.project_name}-${var.environment}-alb-high-5xx-errors" = {
      metric_name         = "HTTPCode_Target_5XX_Count"
      namespace           = "AWS/ApplicationELB"
      statistic           = "Sum"
      period              = 300
      evaluation_periods  = 2
      threshold           = 5
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
      alarm_description = "More than 5 5XX errors in 5 minutes"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "monitoring" {
  for_each             = local.monitoring_alarms
  alarm_name           = each.key
  comparison_operator  = each.value.comparison_operator
  evaluation_periods   = each.value.evaluation_periods
  metric_name          = each.value.metric_name
  namespace            = each.value.namespace
  period               = each.value.period
  statistic            = each.value.statistic
  threshold            = each.value.threshold
  alarm_description    = each.value.alarm_description
  alarm_actions        = [aws_sns_topic.alerts.arn]
  ok_actions           = [aws_sns_topic.alerts.arn]
  dimensions           = each.value.dimensions
}
