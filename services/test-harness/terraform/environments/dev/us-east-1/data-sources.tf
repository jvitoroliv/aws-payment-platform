# data-sources.tf
# Manages data source lookups resources.

### Data Sources

data "aws_secretsmanager_secret_version" "datadog_api_key_secret" {
  secret_id = local.datadog_secret_name
}
