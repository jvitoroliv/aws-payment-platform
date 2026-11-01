# sqs.tf
# Manages SQS queues resources.

resource "aws_lambda_event_source_mapping" "splunklogger_lambda_trigger" {
  event_source_arn = aws_sqs_queue.splunklogger_s3.arn
  function_name    = aws_lambda_function.splunklogger_s3.arn
  enabled          = true
}

resource "aws_sqs_queue" "splunklogger_s3" {
  name                      = "${var.environment}-${var.aws_region}-splunklogger-s3-events"
  visibility_timeout_seconds = 300
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20
  policy = data.aws_iam_policy_document.splunklogger_s3_queue.json
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_notification" "splunklogger_s3_bucket_notification" {
  bucket = data.aws_s3_bucket.access_logs.id

  queue {
    queue_arn     = aws_sqs_queue.splunklogger_s3.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log.gz"
  }
}