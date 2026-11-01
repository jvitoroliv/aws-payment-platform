### Data Sources

# Package Source
data "archive_file" "lambda_splunk_logger_s3" {
  type = "zip"

  source_dir  = "${path.module}/function/src"
  output_path = "${path.module}/function/splunk_logger_s3.zip"
}

# Retrieve Splunk Secrets
data "aws_secretsmanager_secret_version" "splunk_hec" {
  secret_id = local.splunk_secret
}

data "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id = "datadog-api-key"
}

# Retrieve S3 bucket
data "aws_s3_bucket" "access_logs" {
  bucket = "${var.environment}-${var.aws_region}-tag-access-logs"
}

data "aws_iam_policy_document" "splunklogger_s3_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:*:*:${var.environment}-${var.aws_region}-splunklogger-s3-events"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [data.aws_s3_bucket.access_logs.arn]
    }
  }
}