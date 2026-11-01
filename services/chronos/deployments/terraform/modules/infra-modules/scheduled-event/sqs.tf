# sqs.tf
# Part of the SQS queues module.

resource "aws_sqs_queue" "event_queue" {
  count                      = var.aws_region == var.active_region ? 1 : 0
  name                       = "${var.function_name}-queue"
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.error_queue[0].arn}\",\"maxReceiveCount\":4}"
  tags                       = var.tags
  visibility_timeout_seconds = 300
  policy                     = <<EOF
{
  "Version":"2012-10-17",
  "Statement": [{
    "Effect":"Allow",
    "Principal":"*",
    "Action":"sqs:SendMessage",
    "Resource":"arn:aws:sqs:${var.aws_region}:${var.aws_account_number}:${var.function_name}-queue",
    "Condition":{
      "ArnEquals":{
        "aws:SourceArn": ["${join("\", \"", aws_cloudwatch_event_rule.cron.*.arn)}"]
      }
    }
  }]
}
EOF
}

resource "aws_sqs_queue" "error_queue" {
  count                     = var.aws_region == var.active_region ? 1 : 0
  name                      = "${var.function_name}-error"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20
  tags                      = merge(var.tags, { QueueType = "DeadLetter" })
}

resource "aws_lambda_event_source_mapping" "function_mapping" {
  count            = var.aws_region == var.active_region ? 1 : 0
  batch_size       = 1 // Process 1 queue message at a time
  event_source_arn = aws_sqs_queue.event_queue[0].arn
  function_name    = aws_lambda_function.function.arn
}