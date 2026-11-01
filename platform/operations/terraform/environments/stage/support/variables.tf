# variables.tf
# Manages input variable declarations resources.

# Input validation ensures callers provide sane values.
variable "aws_account_number" {
  default = "333333333333"
  type    = string
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "environment" {
  default = "stage"
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

# Documented in the module README with accepted ranges.
variable "instance_type" {
  default = "t2.micro"
  type    = string
}
