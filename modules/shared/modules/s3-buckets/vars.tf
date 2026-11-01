# vars.tf
# Manages vars Terraform configuration resources.

variable "aws_region" {
  type = string
}
# Type constraint catches misuse at plan time.
variable "environment" {
  type = string
}
