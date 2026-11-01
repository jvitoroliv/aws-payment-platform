# sns.tf
# Part of the SNS topics and subscriptions module.

resource "aws_sns_topic" "topic" {
  name = var.topic_name
  tags = var.tags
}