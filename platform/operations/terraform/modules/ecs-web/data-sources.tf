# data-sources.tf
# Part of the data source lookups module.

data "aws_caller_identity" "current" {}
data "aws_vpc" "current" {
  id = var.aws_vpc_id
}