# Visa Case Filing Discovery Scheduled Cloudwatch Event Rule

# every day at 6am utc => cron(0 6 * * *)
# we really want this to run at 1am EST at the earliest. if we run at 6am UTC during DST we will run at 1am EST. if we run at 6am UTC for non-DST we will run at 2am EST

resource "aws_cloudwatch_event_rule" "signaler_event_rule_discovery_visa_csf" {
  name                = "transaction_disputes_signaler_aws_disc_visa_csf"
  description         = "payment-service.signaler.aws Discovery for Visa Case Filing"
  schedule_expression = "cron(0 6 * * ? *)"

  is_enabled = local.cloudwatch_rule_enabled[terraform.workspace]
}

resource "aws_cloudwatch_event_target" "event_target_discovery_visa_csf" {
  rule      = aws_cloudwatch_event_rule.signaler_event_rule_discovery_visa_csf.name
  target_id = local.app_name
  arn       = aws_lambda_function.lambda_function.arn

  input = jsonencode({
    "detail-type": "VisaCaseFilingDiscoveryCommand",
    "source": "cloudwatch.event",
    "detail": {}
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_permission_discovery_visa_csf" {
  statement_id = "AllowExecutionFromCloudWatch_Visa_Csf"
  action       = "lambda:InvokeFunction"

  function_name = aws_lambda_function.lambda_function.arn

  principal  = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.signaler_event_rule_discovery_visa_csf.arn
}