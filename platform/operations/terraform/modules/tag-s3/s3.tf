# s3.tf
# Part of the S3 bucket configuration module.

resource "aws_s3_bucket" "app_script_storage" {
  bucket = local.app_script_storage_bucket_name

  tags = {
    Name = local.app_script_storage_bucket_name
  }
  force_destroy = true
}

resource "aws_s3_bucket_policy" "app_script_storage_bucket_policy" {
  bucket = aws_s3_bucket.app_script_storage.id
  policy = <<END_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AppAccess",
      "Effect": "Allow",
      "Principal":{
        "AWS": "arn:aws:iam::${var.aws_account_number}:root"
       },
       "Action":[
         "s3:DeleteObject",
         "s3:GetObject",
         "s3:PutObject"
       ],
       "Resource":"arn:aws:s3:::${local.app_script_storage_bucket_name}/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${local.app_script_storage_bucket_name}",
        "arn:aws:s3:::${local.app_script_storage_bucket_name}/*"
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

resource "aws_s3_bucket_server_side_encryption_configuration" "app_script_storage" {
  bucket = aws_s3_bucket.app_script_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "aoc_static_content" {
  bucket = local.static_content_bucket_name

  tags = {
    Name = "${var.environment}-images.${var.image_url}"
  }
  force_destroy = false
}

resource "aws_s3_bucket_ownership_controls" "static_content_ownership_control" {
  bucket = aws_s3_bucket.aoc_static_content.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "static_content_storage_bucket_policy" {
  bucket = aws_s3_bucket.aoc_static_content.id
  policy = <<END_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal":{
        "AWS": "arn:aws:iam::${var.aws_account_number}:root"
       },
       "Action":[
         "s3:GetObject"
       ],
       "Resource":"arn:aws:s3:::${local.static_content_bucket_name}/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${local.static_content_bucket_name}",
        "arn:aws:s3:::${local.static_content_bucket_name}/*"
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

resource "aws_s3_bucket_server_side_encryption_configuration" "aoc_static_content" {
  bucket = aws_s3_bucket.aoc_static_content.id

  rule {
    bucket_key_enabled = false

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "aoc_static_content" {
  bucket = aws_s3_bucket.aoc_static_content.id

  error_document {
    key = "logo_new.jpg"
  }

  index_document {
    suffix = "logo_new.jpg"
  }
}

resource "aws_s3_object" "aoc_logo" {
  key    = "logo_new.jpg"
  bucket = aws_s3_bucket.aoc_static_content.bucket
  source = "${path.module}/static/logo_new.jpg"
  etag   = filemd5("${path.module}/static/logo_new.jpg")
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket" "aoc_incoming_mail" {
  force_destroy = true
  bucket        = local.incoming_mail_bucket_name

  tags = {
    Name = local.incoming_mail_bucket_name
  }
}

resource "aws_s3_bucket_policy" "incoming_mail_storage_bucket_policy" {
  bucket = aws_s3_bucket.aoc_incoming_mail.id
  policy = <<END_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GiveSESPermissionToWriteEmail", 
      "Effect": "Allow", 
      "Principal":{ 
        "Service": [ 
          "ses.amazonaws.com"
         ]
       },
      "Action":[
        "s3:PutObject"
       ],
      "Resource": "arn:aws:s3:::${local.incoming_mail_bucket_name}/*",
      "Condition": {"StringEquals": {"aws:Referer": "${var.aws_account_number}"}}
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${local.incoming_mail_bucket_name}",
        "arn:aws:s3:::${local.incoming_mail_bucket_name}/*"
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


# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_server_side_encryption_configuration" "aoc_incoming_mail" {
  bucket = aws_s3_bucket.aoc_incoming_mail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
