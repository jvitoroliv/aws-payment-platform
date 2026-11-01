# variables.tf
# Manages input variable declarations resources.

variable "aws_region" {
  type = string
}
variable "instance_type" {
  type = string
}
# Input validation ensures callers provide sane values.
variable "environment" {
  type = string
}
variable "aws_acct_id" {
  type = string
}
variable "aws_subnet_id" {
  type = string
}
variable "vpc_id" {
  description = "The VPC id"
  type        = string
}

# Override per-environment in tfvars.
variable "delete_on_termination" {
  type    = string
  default = "true"
}

variable "volume_size" {
  type    = number
  default = 200
}

variable "volume_type" {
  type    = string
  default = "gp2"
}
