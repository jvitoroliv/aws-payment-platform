# main.tf
# Manages primary resource definitions resources.

# Dead letter queue
resource "aws_sqs_queue" "deadletter_queue" {
  name = local.deadletter_queue
  visibility_timeout_seconds = local.deadletter_visibility_timeout_seconds
  message_retention_seconds = local.deadletter_message_retention_seconds
  fifo_queue = true
  content_based_deduplication = false
}

# Create SQS Queues
resource "aws_sqs_queue" "transaction_disputes_queues" {
  for_each = local.queues
  name = each.value
  visibility_timeout_seconds = local.visibility_timeout[each.key]
  message_retention_seconds = local.message_retention_seconds
  max_message_size = local.max_message_size
  receive_wait_time_seconds = local.receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn,
    maxReceiveCount = local.max_receive_count
  })
  fifo_queue = true
  content_based_deduplication = false

  depends_on = [aws_sqs_queue.deadletter_queue]
}

# Create acceptance testing queues
resource "aws_sqs_queue" "transaction_disputes_testing_queues" {
  for_each = local.test_queues
  name = each.value
  visibility_timeout_seconds = local.visibility_timeout[each.key]
  message_retention_seconds = local.message_retention_seconds
  max_message_size = local.max_message_size
  receive_wait_time_seconds = local.receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn,
    maxReceiveCount = local.max_receive_count
  })
  fifo_queue = true
  content_based_deduplication = false

  depends_on = [aws_sqs_queue.deadletter_queue]
}

# Create Discovery SQS Queues
resource "aws_sqs_queue" "transaction_disputes_queues_discovery" {
  for_each = local.discovery_queues
  name = each.value
  visibility_timeout_seconds = local.visibility_timeout_30_minutes
  message_retention_seconds = local.message_retention_seconds
  max_message_size = local.max_message_size
  receive_wait_time_seconds = local.receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn,
    maxReceiveCount = local.max_receive_count_retry
  })
  fifo_queue = true
  content_based_deduplication = false

  depends_on = [aws_sqs_queue.deadletter_queue]
}

# Create Discovery Test SQS Queues
resource "aws_sqs_queue" "transaction_disputes_queues_discovery_test" {
  for_each = local.discovery_test_queues
  name = each.value
  visibility_timeout_seconds = local.visibility_timeout_30_minutes
  message_retention_seconds = local.message_retention_seconds
  max_message_size = local.max_message_size
  receive_wait_time_seconds = local.receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn,
    maxReceiveCount = local.max_receive_count_retry
  })
  fifo_queue = true
  content_based_deduplication = false

  depends_on = [aws_sqs_queue.deadletter_queue]
}
