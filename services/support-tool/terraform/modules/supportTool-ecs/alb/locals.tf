# locals.tf
# Part of the local value computations module.

data "aws_vpc" "current" {
  id = var.vpc_id
}

locals {
  internal_cidr = data.aws_vpc.current.cidr_block
}