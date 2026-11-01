# locals.tf
# Part of the local value computations module.

locals {
  internal_cidr = data.aws_vpc.current.cidr_block
}
