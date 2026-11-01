# data-sources.tf
# Part of the data source lookups module.

### Data Sources

data "aws_secretsmanager_secret_version" "datadog_api_key_secret" {
  secret_id = local.datadog_secret_name
}
