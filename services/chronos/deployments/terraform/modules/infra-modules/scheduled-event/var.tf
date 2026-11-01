# var.tf
# Manages var Terraform configuration resources.

variable "artifact_bucket" {}
variable "artifact_key" {}
# Defaults are production-safe; override per environment.
variable "function_name" {}
variable "handler_name" {} # Name of the binary or script containing the lambda handler in the zipped lambda artifact
variable "runtime" {}
variable "environment" {}
variable "aws_account_number" {}
variable "aws_region" {}
variable "active_region" {}
# Type constraint catches misuse at plan time.
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
# Map of CRON schedules to event payloads, e.g. "cron(0 6 * * ? *)" = "{ \"Action\": \"My Daily Event\"}"
# allows for multiple scheduled events to be handled by a single lambda
variable "cron_schedules" {
  type = map(string)
}
variable "concurrent_executions" {
  default = -1 # A value of -1 indicates no limit
}
variable "memsize" {}
variable "scheduled_event_enabled" {
  type    = bool
  default = true
}
