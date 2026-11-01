# cloudwatch.tf
# Manages CloudWatch alarms and dashboards resources.

locals {
  cloudwatch_name_prefix = "${var.function_name}-cron-schedule-"
}

resource "aws_cloudwatch_event_rule" "cron" {
  count               = var.aws_region == var.active_region ? length(var.cron_schedules) : 0
  name                = "${local.cloudwatch_name_prefix}${count.index}"
  schedule_expression = keys(var.cron_schedules)[count.index]
  state               = var.scheduled_event_enabled ? "ENABLED" : "DISABLED"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "cron" {
  count = var.aws_region == var.active_region ? length(var.cron_schedules) : 0
  rule  = "${local.cloudwatch_name_prefix}${count.index}"
  arn   = aws_sqs_queue.event_queue[0].arn
  input = var.cron_schedules[keys(var.cron_schedules)[count.index]]
}
