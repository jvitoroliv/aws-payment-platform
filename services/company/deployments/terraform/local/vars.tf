# vars.tf
# Part of the vars Terraform configuration module.

variable "aws_account_number" {
  default = "000000000000"
}

# Type constraint catches misuse at plan time.
variable "aws_endpoint" {
  default = "localstack"
}

variable "environment" {
  default = "local"
}

# Defaults are production-safe; override per environment.
variable "aws_region" {
  default = "us-east-1"
}
