# variables.tf
# Manages input variable declarations resources.

variable "environment" {
  default = "stage"
  type    = string
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "replication_aws_region" {
  default = "us-west-2"
  type    = string
}

variable "aws_account_number" {
  default = "333333333333"
  type    = string
}
