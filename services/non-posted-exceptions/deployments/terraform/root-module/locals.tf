# locals.tf
# Part of the local value computations module.

locals {
  # Configuration variables
  artifactory_secret = "registry_cloud_credentials"
  crowdstrike_secret = "endpoint_security_cid"
  datadog_secret     = "datadog-api-key"
  is_subprod         = var.environment == "dev" || var.environment == "test"
  shared_bucket      = local.is_subprod ? "corp-subprod-terraform-state-store-${var.region}" : "corp-prod-terraform-state-store-${var.region}"
  shared_region      = var.region == "us-east-1" ? "east" : "west"
  state_key          = "shared-${local.shared_region}-${var.environment}.tfstate"
}
