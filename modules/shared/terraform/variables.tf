# variables.tf
# Part of the input variable declarations module.

### Variable Declarations
# Type constraint catches misuse at plan time.
variable "aws_region" {
  type = string
}
variable "domain" {
  type = string
}
variable "environment" {
  type = string
}
variable "security_groups" {
  default     = {}
  description = "Additional security groups to create that are not derived from allowlists"
  type        = any
}
variable "splunk_dest" {
  type = string
}
variable "splunk_memory_size" {
  default = 256
  type    = number
}
