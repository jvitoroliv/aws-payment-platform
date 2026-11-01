# variables.tf
# Part of the input variable declarations module.

###Variable Definitions

variable "aws_account_number" {
  type = string
}
variable "aws_private_subnets" {
  type = list(string)
}
# Type constraint catches misuse at plan time.
variable "aws_region" {
  type = string
}
variable "aws_vpc_id" {
  type = string
}
variable "environment" {
  type = string
}
variable "memory_size" {
  default = 256
  type    = number
}
# Documented in the module README with accepted ranges.
variable "source_s3_bucket" {
  type = string
}
variable "source_s3_key" {
  type = string
}
variable "splunk_dest" {
  type = string
}
