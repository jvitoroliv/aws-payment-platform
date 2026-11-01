# var.tf
# Manages var Terraform configuration resources.

variable "artifact_path" {}
variable "active_region" {}
variable "aws_region" {}
variable "environment" {}
variable "aging_event_sns_topic_arn" {}
variable "artifact_bucket" {}
variable "aws_account_number" {}
variable "mongo_uri" {}
variable "mongo_username" {}
# Defaults are production-safe; override per environment.
variable "vpc_cidr" {}
variable "vpc_id" {}
variable "logconsumer_lambda_arn" {}
variable "dd_api_key" {}
variable "datadog_lambda_layer" {}

variable "code_version" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "artifact_extension" {
  default = ".zip"
}

# Applied on a per Lambda basis
# Documented in the module README with accepted ranges.
variable "concurrent_executions" {
  default = -1 # A value of -1 indicates no limit
}

variable "memsize" {
  default = 256
}

variable "scheduled_event_enabled" {
  type    = bool
  default = true
}
