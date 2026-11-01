# lambdas.tf
# Manages Lambda function definitions resources.

resource "aws_s3_bucket" "lambda_content" {
  bucket = "${var.environment}-${var.aws_region}-app-artifacts-lambda"

  tags = {
    Name        = "${var.environment}-app-artifacts-lambda"
  }
  force_destroy = false
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_content_encryption_configuration" {
  bucket = aws_s3_bucket.lambda_content.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "lambda_content_versioning" {
  bucket = aws_s3_bucket.lambda_content.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption at rest is enforced via bucket policy.
# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_policy" "lambda_bucket_policy" {
  bucket = aws_s3_bucket.lambda_content.id
  policy = <<END_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-lambda",
        "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-lambda/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
END_POLICY
}