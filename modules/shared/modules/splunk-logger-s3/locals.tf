# locals.tf
# Manages local value computations resources.

locals {
  # Configuration variables
  environment    = var.environment == "dev" || var.environment == "test"
  splunk_secret  = var.environment == "stage" ? "stage-splunk-hec-token" : local.environment ? "subprod-${var.environment}-splunk-hec-token" : "prod-${var.environment}-splunk-hec-token"
  splunk_token   = jsondecode(data.aws_secretsmanager_secret_version.splunk_hec.secret_string)
  datadog_secret = jsondecode(data.aws_secretsmanager_secret_version.datadog_api_key.secret_string)

}
