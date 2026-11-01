# S3 Encryption Migration Trigger
# Schedule: October 31, 2025 at 2:00 AM UTC
# Format: cron(minute hour day month ? year)

resource "aws_cloudwatch_event_rule" "s3_encryption_trigger" {
  name                = "transaction_disputes_s3_encryption"
  description         = "Trigger S3 encryption migration"
  schedule_expression = "cron(0 2 31 10 ? 2025)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "s3_encryption_target" {
  rule      = aws_cloudwatch_event_rule.s3_encryption_trigger.name
  target_id = "s3-encryption"
  arn       = aws_lambda_function.lambda_function.arn

  input = jsonencode({
    "detail-type" = "EncryptS3FilesCommand"
    "source"      = "cloudwatch.event"
    "detail" = {
      "bucketName" = "payment-service-files"
    }
  })
}

resource "aws_lambda_permission" "s3_encryption_permission" {
  statement_id  = "AllowS3EncryptionTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_encryption_trigger.arn
}
