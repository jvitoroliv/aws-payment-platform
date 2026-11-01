# main.tf
# Manages primary resource definitions resources.

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backlog_per_task" {
  name               = "${var.service_name}-sqs-backlog-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.target_value
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown

    customized_metric_specification {
      metrics {
        label = "Get the queue size (the number of messages waiting to be processed)"
        id    = "m1"

        metric_stat {
          metric {
            metric_name = "ApproximateNumberOfMessagesVisible"
            namespace   = "AWS/SQS"

            dimensions {
              name  = "QueueName"
              value = var.queue_name
            }
          }

          stat = "Sum"
        }

        return_data = false
      }

      metrics {
        label = "Get the ECS running task count (the number of currently running tasks)"
        id    = "m2"

        metric_stat {
          metric {
            metric_name = "RunningTaskCount"
            namespace   = "ECS/ContainerInsights"

            dimensions {
              name  = "ClusterName"
              value = var.cluster_name
            }

            dimensions {
              name  = "ServiceName"
              value = var.service_name
            }
          }

          stat = "Average"
        }

        return_data = false
      }

      metrics {
        label       = "Calculate the backlog per task"
        id          = "e1"
        expression  = "m1 / m2"
        return_data = true
      }
    }
  }
}
