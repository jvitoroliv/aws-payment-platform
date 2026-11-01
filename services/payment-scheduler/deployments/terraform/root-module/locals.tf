# locals.tf
# Part of the local value computations module.

locals {
  # Configuration variables
  artifactory_secret = "registry_cloud_credentials"
  environment        = var.environment == "dev" || var.environment == "test"
  datadog_secret     = "datadog-api-key"
  datadog_api_key    = jsondecode(data.aws_secretsmanager_secret_version.datadog-api-key.secret_string)
  shared_bucket      = local.environment ? "corp-subprod-terraform-state-store-${var.aws_region}" : "corp-prod-terraform-state-store-${var.aws_region}"
  shared_region      = var.aws_region == "us-east-1" ? "east" : "west"
  state_key          = "shared-${local.shared_region}-${var.environment}.tfstate"
}