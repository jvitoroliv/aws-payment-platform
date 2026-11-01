# locals.tf
# Manages local value computations resources.

locals {
  # Configuration variables
  artifactory_secret             = "registry_cloud_credentials"
  crowdstrike_secret             = "endpoint_security_cid"
  endpoint_security_cid_arg_secret_arn = "${data.aws_secretsmanager_secret.crowdstrike.arn}:endpoint_security_cid::" # "endpoint_security_cid" is the JSON key within the secret
  datadog_secret                 = "datadog-api-key"
  datadog_api_key_secret_arn     = "${data.aws_secretsmanager_secret_version.datadog-api-key.arn}:datadog-api-key::" # "datadog-api-key" is the JSON key within the secret
  is_subprod                     = var.environment == "dev" || var.environment == "test"
  shared_bucket                  = local.is_subprod ? "corp-subprod-terraform-state-store-${var.region}" : "corp-prod-terraform-state-store-${var.region}"
  shared_region                  = var.region == "us-east-1" ? "east" : "west"
  state_key                      = "shared-${local.shared_region}-${var.environment}.tfstate"
}
