# main.tf
# Part of the primary resource definitions module.

# Override per-environment in tfvars.
variable "s3_bucket_ses"           { default = "" }
variable "domain"                  { default = "notifications.example.com" }
variable "mail_from_address"       { default = "mail-dev" }
# Type constraint catches misuse at plan time.
variable "rule_set_name"           { default = "emails-to-s3" }
variable "ses_receipt_rule"        { default = "emails-to-s3" }
variable "ses_rule_enabled"        { default = true }
variable "ses_scan_enabled"        { default = true }



###S3 bucket for sending the emails###
resource "aws_s3_bucket" "ses" {
  bucket = "${var.s3_bucket_ses}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
            {
            "Sid": "Stmt1504640908907",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${var.s3_bucket_ses}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        },
    {
            "Sid": "Stmt1581028151601",
            "Action": "s3:PutObject",
            "Effect": "Allow",
            "Principal": {
                "Service": "ses.amazonaws.com"
            },
            "Resource": "arn:aws:s3:::${var.s3_bucket_ses}/*"
        }
    ]
}
POLICY
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    id      = "delete after 90 days"
    enabled = true
    expiration {
      days = 90
    }
  }
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_public_access_block" "ses" {
  bucket = "${var.s3_bucket_ses}"

    block_public_acls       = true
    block_public_policy     = true
    restrict_public_buckets = true
    ignore_public_acls      = true
}
  

## domain from where you send an email
resource "aws_ses_domain_identity" "mailsvs" {
   domain = "${var.domain}"
}
## email which will be used for sending
resource "aws_ses_domain_mail_from" "mailsvs" {
  domain           = "${aws_ses_domain_identity.mailsvs.domain}"
  mail_from_domain = "${var.mail_from_address}.${aws_ses_domain_identity.mailsvs.domain}"
}
###Verification needs to be done manual as the domain is in the AOC legacy account####
resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = "${var.rule_set_name}"
}

resource "aws_ses_receipt_rule" "main" {
  name          = "${var.ses_receipt_rule}"
  rule_set_name = "${aws_ses_receipt_rule_set.main.rule_set_name}"
  enabled       = "${var.ses_rule_enabled}"
  scan_enabled  = "${var.ses_scan_enabled}"
//needs to be changed
  s3_action = {
    bucket_name = "${var.s3_bucket_ses}"
    object_key_prefix = "mailbox/allemails"
    position = 1
  }
}

# Activate rule set
resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = "${aws_ses_receipt_rule_set.main.rule_set_name}"
}