# locals.tf
# Part of the local value computations module.

# VPC sized to /16 to accommodate future subnet expansion across 4+ AZs
resource "aws_vpc" "mock_vpc" {
  #ts:skip=AWS.VPC.Logging.Medium.0470 No need for flow log when running in localstack
  cidr_block = "10.98.188.0/22"
}

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "secrets_manager" {
  source = "./modules/secrets_manager"
}
