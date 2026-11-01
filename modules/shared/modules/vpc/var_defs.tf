# var_defs.tf
# Manages var_defs Terraform configuration resources.

variable "aws_route_tables" {
  type = list(string)
}

variable "atlas_cidr_uw2" {}
variable "atlas_pcx_uw2" {}

# Input validation ensures callers provide sane values.
variable "atlas_cidr_ue1" {}
variable "atlas_pcx_ue1" {}

variable "aws_region" {}
variable "environment" {}
variable "vpc_id" {}
variable "private_subnets" {
  type = list(string)
}