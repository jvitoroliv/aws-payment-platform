# locals.tf
# Part of the local value computations module.


locals {
  # Configuration variables
  datadog_secret_name = "datadog-api-key"
  datadog_secret_arn  = "${data.aws_secretsmanager_secret_version.datadog_api_key_secret.arn}:datadog-api-key::"
}