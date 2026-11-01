# locals.tf
# Part of the local value computations module.

locals {
  # Configuration variables
  is_subprod             = var.environment != "prod"
  nonprod_or_prod        = local.is_subprod ? "nonprod" : "prod"
  artifactory_secret     = "registry_cloud_credentials"
  chronos_dynamodb_table = "tag-${var.environment}-state-store"
  chronos_state_key      = "${var.environment}-${var.aws_region}-chronos.tfstate"
  chronos_api            = var.chronos_api == "" ? data.terraform_remote_state.chronos.outputs.api_invoke_url : var.chronos_api
  datadog_secret         = "datadog-api-key"
  datadog_api_key        = jsondecode(data.aws_secretsmanager_secret_version.datadog-api-key.secret_string)
  endpoint_security_cid        = data.aws_ssm_parameter.crowdstrike-cid.value
  environment            = var.environment == "dev" || var.environment == "test"
  shared_region          = var.aws_region == "us-east-1" ? "east" : "west"
  state_key              = "shared-${local.shared_region}-${var.environment}.tfstate"
  active_region          = terraform_data.previous_active_region.input
  mock_version          = terraform_data.previous_mock_version.input

  state_bucket = {
    dev   = "corp-subprod-terraform-state-store-${var.aws_region}"
    test  = "corp-subprod-terraform-state-store-${var.aws_region}"
    stage = "corp-stage-terraform-state-store-${var.aws_region}"
    prod  = "corp-prod-terraform-state-store-${var.aws_region}"
  }
}
