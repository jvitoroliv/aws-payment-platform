### Data Sources

# Package Source
# NOTE: If you're updating this file, you will need to upload the zip to AWS S3 Lambda Buckets!
data "archive_file" "lambda_splunk_logger" {
  type = "zip"

  source_dir  = "${path.module}/function/src"
  output_path = "${path.module}/function/splunk_logger.zip"
}

# Retrieve S3 Bucket Details for Lambda
data "aws_s3_object" "splunklogger_source" {
  bucket = var.source_s3_bucket
  key    = var.source_s3_key
}

# Retrieve Splunk Secrets
data "aws_secretsmanager_secret_version" "splunk_hec" {
  secret_id = local.splunk_secret
}

data "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id = "datadog-api-key"
}
