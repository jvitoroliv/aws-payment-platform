# signaler_triggers_etl_incremental_sync.tf
# Manages signaler_triggers_etl_incremental_sync Terraform configuration resources.

# Hourly trigger to run the ETL incremental sync process

resource "aws_cloudwatch_event_rule" "etl_incremental_sync_trigger" {
  name                = "transaction_disputes_etl_incremental_sync"
  description         = "Trigger Incremental ETL sync process from Legacy Disputes Database"
  schedule_expression = "cron(0 * ? * * *)"
  is_enabled          = local.cloudwatch_rule_enabled[terraform.workspace]
}

resource "aws_cloudwatch_event_target" "etl_incremental_sync_target" {
  rule      = aws_cloudwatch_event_rule.etl_incremental_sync_trigger.name
  target_id = "etl-incremental-sync"
  arn       = aws_lambda_function.lambda_function.arn

  input = jsonencode({
    "detail-type" = "SyncDisputesEtlCommand"
    "source"      = "cloudwatch.event"
    "detail" = {}
  })
}

resource "aws_lambda_permission" "etl_incremental_sync_permission" {
  statement_id  = "AllowExecutionFromCloudWatch_IncrementalEtlSync"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.etl_incremental_sync_trigger.arn
}
