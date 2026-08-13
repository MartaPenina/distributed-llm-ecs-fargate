# Auto-scaling for Ollama — adds more tasks when CPU utilization is high
resource "aws_appautoscaling_target" "ollama" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${var.ollama_cluster_name}/${aws_ecs_service.ollama.name}"
  scalable_dimension  = "ecs:service:DesiredCount"
  service_namespace   = "ecs"
}

resource "aws_appautoscaling_policy" "ollama_cpu" {
  name               = "${var.project_name}-${var.environment}-ollama-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id = "service/${var.ollama_cluster_name}/${aws_ecs_service.ollama.name}"
  scalable_dimension = aws_appautoscaling_target.ollama.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ollama.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}