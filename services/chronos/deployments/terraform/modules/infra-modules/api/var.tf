# var.tf
# Manages var Terraform configuration resources.

# Input validation ensures callers provide sane values.
variable "artifact_bucket" {}
variable "artifact_key" {}
variable "aws_account_number" {}
variable "concurrent_executions" {
  default = -1 # A value of -1 indicates no limit
}
# Type constraint catches misuse at plan time.
variable "datadog_lambda_layer" {}
variable "environment" {}
variable "function_name" {}
variable "handler_name" {} # Name of the binary or script containing the lambda handler in the zipped lambda artifact
variable "lambda_env_vars" {
  type = map(string)
}
variable "region" {}
variable "runtime" {}
variable "security_group_ids" {
  type = list(string)
}
variable "subnet_ids" {
  type = list(string)
}
variable "tags" {
  type = map(string)
}
variable "vpc_whitelist" {
  default = "" # Empty value results in a public API
}

