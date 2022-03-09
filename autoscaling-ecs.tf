resource "aws_appautoscaling_target" "this" {
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  min_capacity       = var.scaling_min_capacity
  max_capacity       = var.scaling_max_capacity
}

resource "aws_appautoscaling_policy" "this_target_tracking" {
  count = var.autoscaling_policy_type == "TargetTrackingScaling" && var.autoscaling_enabled == true ? 1 : 0 # Only create if autoscaling is enabled and is set to TargetTrackingScaling
  name               = var.service_name
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = var.ecs_scale_in_cooldown
    scale_out_cooldown = var.ecs_scale_out_cooldown
    target_value       = var.ecs_autoscaling_metric_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}