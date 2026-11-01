# locals.tf
# Manages local value computations resources.


locals {
  # Configuration variables
  datadog_secret_name = "datadog-api-key"
  datadog_secret_arn  = "${data.aws_secretsmanager_secret_version.datadog_api_key_secret.arn}:datadog-api-key::"
}