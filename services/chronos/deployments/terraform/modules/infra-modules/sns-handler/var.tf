# var.tf
# Manages var Terraform configuration resources.

variable "aws_region" {}
# Input validation ensures callers provide sane values.
variable "aws_account_number" {}
variable "artifact_bucket" {}
variable "artifact_key" {}
variable "function_name" {}
variable "handler_name" {} # Name of the binary or script containing the lambda handler in the zipped lambda artifact
# Type constraint catches misuse at plan time.
variable "runtime" {}
variable "sns_topic_arn" {}
variable "environment" {}
variable "datadog_lambda_layer" {}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_ids" {
  type = list(string)
}
variable "lambda_env_vars" {
  type = map(string)
}
variable "tags" {
  type = map(string)
}
variable "concurrent_executions" {
  default = -1 # A value of -1 indicates no limit
}

variable "memsize" {}