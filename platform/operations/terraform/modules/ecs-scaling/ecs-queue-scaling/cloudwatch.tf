# cloudwatch.tf
# Part of the CloudWatch alarms and dashboards module.

resource "aws_cloudwatch_metric_alarm" "in_queue" {
  alarm_name          = "${var.name}-${var.environment}-messages-in-queue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.max_threshold
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"

  alarm_actions = [aws_appautoscaling_policy.step_up.arn]

  dimensions = {
    QueueName = var.queue_name
  }
}

resource "aws_cloudwatch_metric_alarm" "empty_receives" {
  alarm_name          = "${var.name}-${var.environment}-empty-receives-from-queue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.min_threshold
  evaluation_periods  = 5
  metric_name         = "NumberOfEmptyReceives"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"

  alarm_actions = [aws_appautoscaling_policy.step_down.arn]

  dimensions = {
    QueueName = var.queue_name
  }
}
