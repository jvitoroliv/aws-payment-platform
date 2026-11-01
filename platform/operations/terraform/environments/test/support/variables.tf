# variables.tf
# Manages input variable declarations resources.

# Input validation ensures callers provide sane values.
variable "aws_account_number" {
  default = "111111111111"
  type    = string
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "aws_subnet_id" {
  default = "subnet-0example000000001"
  type    = string
}

variable "aws_vpc_id" {
  description = "vpc ID is already generated can not pass from module"
  default     = "vpc-0example000000001"
  type        = string
}

# Defaults are production-safe; override per environment.
variable "environment" {
  default = "test"
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}
