# support.tf
# Part of the support Terraform configuration module.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "support" {
  source        = "../../../modules/tag-support"
  aws_region    = var.aws_region
  environment   = var.environment
  aws_acct_id   = var.aws_account_number
  aws_subnet_id = var.aws_subnet_id
  vpc_id        = var.aws_vpc_id
  instance_type = var.instance_type
}
