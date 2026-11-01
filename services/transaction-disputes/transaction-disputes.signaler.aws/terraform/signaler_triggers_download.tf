# Each rule and target is designed to faciliate a temporal triggering of the signaler
# that commands downstream services to download files
resource "aws_cloudwatch_event_rule" "signaler_event_rule_download" {
  for_each = local.download_clients
  
  name                = "transaction_disputes_signaler_aws_download_${each.key}"
  description         = "payment-service.signaler.aws Download from ${each.key}"
  schedule_expression = each.value

  is_enabled = local.cloudwatch_rule_enabled[terraform.workspace]
}

resource "aws_cloudwatch_event_target" "event_target_download" {
  for_each = aws_cloudwatch_event_rule.signaler_event_rule_download

  rule      = aws_cloudwatch_event_rule.signaler_event_rule_download[each.key].name
  target_id = local.app_name
  arn       = aws_lambda_function.lambda_function.arn

  input = jsonencode({
      "detail-type": "DisputedTransactionFileDownloadCommand",
      "source": "cloudwatch.event",
      "detail": {"disputeSource": each.key}
    })
}

resource "aws_lambda_permission" "allow_cloudwatch_permission" {
  for_each = aws_cloudwatch_event_rule.signaler_event_rule_download

  statement_id = "AllowExecutionFromCloudWatch_${each.key}"
  action       = "lambda:InvokeFunction"

  function_name = aws_lambda_function.lambda_function.arn

  principal  = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.signaler_event_rule_download[each.key].arn
}
