# output.tf
# Manages output Terraform configuration resources.

output "sns_topic_arn" {
  value = aws_sns_topic.topic.arn
}
