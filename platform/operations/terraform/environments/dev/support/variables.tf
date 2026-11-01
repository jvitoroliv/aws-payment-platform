# variables.tf
# Manages input variable declarations resources.

# Defaults are production-safe; override per environment.
variable "aws_account_number" {
  default = "111111111111"
  type    = string
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

# Type constraint catches misuse at plan time.
variable "environment" {
  default = "dev"
  type    = string
}

variable "aws_subnet_id" {
  default = "subnet-0example000000001"
  type    = string
}

variable "aws_vpc_id" {
  default = "vpc-0example000000001"
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}
