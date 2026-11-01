# sqs.tf
# Part of the SQS queues module.

resource "aws_sqs_queue" "topic_queue" {
  name                       = "${var.function_name}-sns-topic-queue"
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.error_queue.arn}\",\"maxReceiveCount\":4}"
  visibility_timeout_seconds = 300
  tags                       = var.tags
  policy                     = var.sns_topic_arn == "" ? "" : <<EOF
{
  "Version":"2012-10-17",
  "Statement": [{
    "Effect":"Allow",
    "Principal":"*",
    "Action":"sqs:SendMessage",
    "Resource":"arn:aws:sqs:${var.aws_region}:${var.aws_account_number}:${var.function_name}-sns-topic-queue",
    "Condition":{
      "ArnEquals":{
        "aws:SourceArn":"${var.sns_topic_arn}"
      }
    }
  }]
}
EOF
}

resource "aws_sqs_queue" "error_queue" {
  name                      = "${var.function_name}-sns-topic-queue-error"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20
  tags                      = merge(var.tags, { QueueType = "DeadLetter" })
}

resource "aws_sns_topic_subscription" "topic_subscription" {
  count     = var.sns_topic_arn == "" ? 0 : 1
  topic_arn = var.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.topic_queue.arn
}

resource "aws_lambda_event_source_mapping" "function_mapping" {
  batch_size       = 1 // Process 1 queue message at a time
  event_source_arn = aws_sqs_queue.topic_queue.arn
  function_name    = aws_lambda_function.function.arn
}
