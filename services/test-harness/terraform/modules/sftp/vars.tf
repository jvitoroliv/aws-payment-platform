# vars.tf
# Part of the vars Terraform configuration module.

variable "aws_account_number" {}
variable "aws_region" {}
variable "aws_private_subnets" {}
# Defaults are production-safe; override per environment.
variable "aws_vpc_id" {}
variable "environment" {}
