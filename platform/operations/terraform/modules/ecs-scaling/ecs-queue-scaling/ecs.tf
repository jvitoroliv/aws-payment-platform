# ecs.tf
# Manages ECS service definitions resources.

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
}

resource "aws_appautoscaling_policy" "step_down" {
  name               = "${var.name}-${var.environment}-step-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 15
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = "0"
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_policy" "step_up" {
  name               = "${var.name}-${var.environment}-step-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 180
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = "0"
      scaling_adjustment          = 1
    }
  }
}
