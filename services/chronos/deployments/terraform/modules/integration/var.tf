# var.tf
# Manages var Terraform configuration resources.

variable "topic_arn_cycling" {}
variable "topic_arn_latefee" {}
# Type constraint catches misuse at plan time.
variable "topic_arn_delinquency" {}
variable "statement_queue" {}
variable "card-processor_queue" {}
