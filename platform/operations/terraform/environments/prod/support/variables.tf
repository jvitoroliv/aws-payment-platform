# variables.tf
# Part of the input variable declarations module.

variable "aws_account_number" {
  default = "222222222222"
  type    = string
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "environment" {
  default = "prod"
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
