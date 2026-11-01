# locals.tf
# Manages local value computations resources.

locals {
  # Configuration variables
  aws_vars         = yamldecode(file("../configurations/aws/vars.yaml"))
  aws_account      = local.aws_vars.tenancy[var.environment].aws_account_id
  tenancy          = local.aws_vars.tenancy[var.environment][var.aws_region]
  external_id      = local.aws_vars.tenancy[var.environment].iam.external_id
  peering          = local.tenancy.atlas.peering
}
