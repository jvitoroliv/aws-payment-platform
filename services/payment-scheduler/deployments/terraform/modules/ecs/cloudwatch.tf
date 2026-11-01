# cloudwatch.tf
# Part of the CloudWatch alarms and dashboards module.

resource "aws_cloudwatch_log_group" "payments_scheduler_log_group" {
  name = format("/aws/fargate/%s/%s", aws_ecs_cluster.payments_scheduler_cluster.name, var.environment)
}

resource "aws_cloudwatch_log_group" "crowdstrike_log_group" {
  name = format("/aws/fargate/%s/%s/crowdstrike", aws_ecs_cluster.payments_scheduler_cluster.name, var.environment)
}

resource "aws_cloudwatch_log_group" "datadog" {
  name = format("/aws/fargate/%s/payments-datadog", var.environment)
}

resource "aws_cloudwatch_log_subscription_filter" "payments_scheduler_log_subscription" {
  count           = var.log_script_filter_count
  destination_arn = var.log_lambda_arn
  filter_pattern  = ""
  log_group_name  = aws_cloudwatch_log_group.payments_scheduler_log_group.name
  name            = aws_ecs_service.payments_scheduler_service.name
}
