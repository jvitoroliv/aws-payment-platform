# locals.tf
# Manages local value computations resources.

data "aws_caller_identity" "current" {}
data "aws_vpc" "current" {
  id = var.aws_vpc_id
}

locals {
  internal_cidr = data.aws_vpc.current.cidr_block
}