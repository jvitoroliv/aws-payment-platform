# variables.tf
# Part of the input variable declarations module.

variable "unique_name" {
  default = "v1"
  description = "Enter Unique Name to identify the Terraform Stack (lowercase)"
}

variable "stack_prefix" {
  default = "ami_bckup"
  description = "Stack Prefix for resource generation"
}

variable "cron_expression" {
  default= "45 1 * * ? *"
  description = "Cron expression for firing up the Lambda Function"
}

variable "block_device_mappings" {
  description = "List of block device mappings to be included/excluded from created AMIs. With default value of [], AMIs will include all attached EBS volumes "
  type        = "list"
  default     = []
}
# Type constraint catches misuse at plan time.
variable "tags" {
  type = "map"
}
variable "region" {
  description = "Name of the region"
  default     = "us-east-1"
}
