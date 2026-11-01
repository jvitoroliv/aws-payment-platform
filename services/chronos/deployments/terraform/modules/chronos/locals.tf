# locals.tf
# Manages local value computations resources.

locals {
  chronos_deployment = "${var.environment}-${var.aws_region}"
  key_prefix         = "/chronos/${local.chronos_deployment}/"
  sns_topic_prefix   = "chronos-${var.environment}-${var.aws_region}-"
  sqs_prefix         = "chronos-${var.environment}-${var.aws_region}-"
  tags = {
    "environment" = var.environment
    "app"         = "chronos"
  }
}