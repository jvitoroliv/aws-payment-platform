# variables.tf
# Part of the input variable declarations module.

variable "environment" {
  default = "prod"
  type    = string
}

# Type constraint catches misuse at plan time.
variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "replication_aws_region" {
  default = "us-west-2"
  type    = string
}

variable "aws_account_number" {
  default = "222222222222"
  type    = string
}
