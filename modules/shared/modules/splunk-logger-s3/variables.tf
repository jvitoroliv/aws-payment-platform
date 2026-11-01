# variables.tf
# Part of the input variable declarations module.

###Variable Definitions

variable "aws_private_subnets" {
  type = list(string)
}
variable "aws_region" {
  type = string
}
variable "aws_vpc_id" {
  type = string
}
# Type constraint catches misuse at plan time.
variable "environment" {
  type = string
}
variable "memory_size" {
  default = 256
  type    = number
}
variable "splunk_dest" {
  type = string
}
