# cloudwatch.tf
# Part of the CloudWatch alarms and dashboards module.

resource "aws_cloudwatch_log_subscription_filter" "application" {
  for_each = {
    for key, service in module.aws_ecs.services : key => {
      log_group_name = service.container_definitions["application"].cloudwatch_log_group_name
      name           = try(var.services[key].application_log_subscription_filter_name, "${key}-application")
    }
  }

  destination_arn = var.log_lambda_arn
  filter_pattern  = ""
  log_group_name  = each.value.log_group_name
  name            = each.value.name
}
