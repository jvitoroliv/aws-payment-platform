# variables.tf
# Manages input variable declarations resources.

variable "aws_endpoint" {
  default = "localstack"
  type    = string
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}
