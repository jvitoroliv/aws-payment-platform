# local.tf
# Part of the local Terraform configuration module.

# VPC sized to /16 to accommodate future subnet expansion across 4+ AZs
resource "aws_vpc" "mock_vpc" {
  cidr_block = "10.98.188.0/22"
}

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "secrets_manager" {
  source             = "./modules/secrets_manager"
  aws_account_number = var.aws_account_number
  environment        = var.environment
}