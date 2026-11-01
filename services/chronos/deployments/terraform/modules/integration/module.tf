# module.tf
# Part of the module Terraform configuration module.

resource "aws_sns_topic_subscription" "topic_subscription_cycling" {
  topic_arn            = var.topic_arn_cycling
  protocol             = "sqs"
  endpoint             = var.statement_queue
  raw_message_delivery = true
}

resource "aws_sns_topic_subscription" "topic_subscription_latefee" {
  topic_arn            = var.topic_arn_latefee
  protocol             = "sqs"
  endpoint             = var.card-processor_queue
  raw_message_delivery = true
}

resource "aws_sns_topic_subscription" "topic_subscription_delinquency" {
  topic_arn            = var.topic_arn_delinquency
  protocol             = "sqs"
  endpoint             = var.card-processor_queue
  raw_message_delivery = true
}
