# locals.tf
# Manages local value computations resources.

locals {
  artifactory_secret = "registry_cloud_credentials"
  crowdstrike_secret = "endpoint_security_cid"
  datadog_secret     = "datadog-api-key"
  shared_region      = var.region == "us-east-1" ? "east" : "west"
  state_key          = "shared-${local.shared_region}-${var.environment}.tfstate"
  state_bucket       = contains(["dev", "test"], var.environment) ? "corp-subprod-terraform-state-store-${var.region}" : "new-finservtag-${var.environment}-terraform-state-store-${var.region}"
  state_table        = contains(["dev", "test"], var.environment) ? "tag-subprod-state-store" : "tag-${var.environment}-state-store"
}
