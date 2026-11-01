# auto-scaling.tf
# Manages auto-scaling Terraform configuration resources.

resource "aws_appautoscaling_target" "payments_scheduler_autoscaling_target" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.payments_scheduler_cluster.name}/${aws_ecs_service.payments_scheduler_service.name}"
  role_arn           = "arn:aws:iam::${var.aws_account_id}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "payments_scheduler_policy_requests" {
  name               = "${var.app_id}-scale-request"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.payments_scheduler_autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.payments_scheduler_autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.payments_scheduler_autoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    target_value       = 100
  }
}
