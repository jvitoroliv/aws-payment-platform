# access-logs.tf
# Part of the access-logs Terraform configuration module.

# S3 Bucket for storing ALB Access logs.
resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.environment}-${var.aws_region}-tag-access-logs"
  force_destroy = false
  tags = {
    name        = "${var.environment}-access-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_encryption_configuration" {
  bucket = aws_s3_bucket.access_logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_versioning" "access_logs_versioning" {
  bucket = aws_s3_bucket.access_logs.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_policy" "access_logs_bucket_policy" {
  bucket = aws_s3_bucket.access_logs.id
  policy = <<END_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowELBRootAccount",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.main.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.environment}-${var.aws_region}-tag-access-logs/*"
    },
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.environment}-${var.aws_region}-tag-access-logs/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${var.environment}-${var.aws_region}-tag-access-logs"
    }
  ]
}
END_POLICY
}
