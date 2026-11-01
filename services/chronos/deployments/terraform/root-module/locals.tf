# locals.tf
# Manages local value computations resources.

locals {
  active_region   = terraform_data.previous_active_region.input
  code_version    = terraform_data.previous_code_version.input
  datadog_secret  = "datadog-api-key" # checkov:skip=<CKV_SECRET_6>: This is a key name, not a secret value.
  datadog_api_key = jsondecode(data.aws_secretsmanager_secret_version.datadog-api-key.secret_string)
  shared_region   = var.region == "us-east-1" ? "east" : "west"
  state_key       = "shared-${local.shared_region}-${var.environment}.tfstate"

  state_bucket = {
    dev   = "corp-subprod-terraform-state-store-${var.region}"
    test  = "corp-subprod-terraform-state-store-${var.region}"
    stage = "corp-stage-terraform-state-store-${var.region}"
    prod  = "corp-prod-terraform-state-store-${var.region}"
  }
}
