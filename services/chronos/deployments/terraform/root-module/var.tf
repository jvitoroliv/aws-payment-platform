# var.tf
# Part of the var Terraform configuration module.

variable "active_region" {
  type        = string
  default     = ""
  description = "Active region for the deployment. If set to an empty string, the current active region from state will be used."

  # Fail fast: catch misconfigurations at plan time, not apply time.
  validation {
    condition     = var.active_region == "" ? true : contains(["us-east-1", "us-west-2"], var.active_region)
    error_message = "The variable 'active_region' must be \"\", \"us-east-1\" or \"us-west-2\"."
  }
}
variable "aging_event_sns_topic_arn" {}
variable "artifact_bucket" {}
variable "artifact_extension" {
  default = ".zip"
}
# Type constraint catches misuse at plan time.
variable "aws_account_number" {}
variable "code_version" {
  default     = ""
  description = "Version of the application code to deploy. If set to an empty string, the Lambda Functions will use the same code version as they currently have. For the initial deployment a non empty value must be supplied."
  type        = string
} # Typically the commit hash
variable "card-processor_queue_arn" {}
# Applied on a per Lambda basis
# Input validation ensures callers provide sane values.
variable "concurrent_executions" {
  default = -1 # A value of -1 indicates no limit
}
variable "environment" {}
variable "memsize" {}
variable "mongo_uri" {}
variable "mongo_username" {}
variable "region" {}
variable "statements_queue_arn" {}
variable "subnet_ids" {
  type = list(string)
}
variable "vpc_id" {}
variable "scheduled_event_enabled" {
  type    = bool
  default = true
}
