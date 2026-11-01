# signaler_triggers_etl.tf
# Part of the signaler_triggers_etl Terraform configuration module.

﻿# Populate ETL Scheduled Cloudwatch Event Rule

# every hour at 0 minutes => cron(0 * * * ? *)

resource "aws_cloudwatch_event_rule" "signaler_event_rule_etl_test" {
  name                = "transaction_disputes_signaler_aws_etl_test"
  description         = "payment-service.signaler.aws ETL Test"
  schedule_expression = "cron(0 3 * * ? *)"

  is_enabled = local.cloudwatch_rule_enabled[terraform.workspace]
}

resource "aws_cloudwatch_event_target" "event_target_etl_test" {
  rule      = aws_cloudwatch_event_rule.signaler_event_rule_etl_test.name
  target_id = local.app_name
  arn       = aws_lambda_function.lambda_function.arn

  input = jsonencode({
    "detail-type": "FullEtlCommand",
    "source": "cloudwatch.event",
    "detail": {}
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_permission_etl_test" {
  statement_id = "AllowExecutionFromCloudWatch_Etl_Test"
  action       = "lambda:InvokeFunction"

  function_name = aws_lambda_function.lambda_function.arn

  principal  = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.signaler_event_rule_etl_test.arn
}
