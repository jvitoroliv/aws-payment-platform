# s3.tf
# Manages S3 bucket configuration resources.

locals {
  is_valid_retention            = contains(["dev", "test"], var.environment) ? true : var.regular_file_expiration_days >= 365
  is_valid_two_years            = contains(["dev", "test"], var.environment) ? true : var.critical_file_expiration_days >= 790
  is_valid_seven_years          = contains(["dev", "test"], var.environment) ? true : var.long_term_file_expiration_days >= 2556
  is_valid_transition           = var.regular_file_transition_days < var.regular_file_expiration_days
  is_valid_critical_transition  = var.critical_file_transition_days < var.critical_file_expiration_days
  is_valid_long_term_transition = var.long_term_file_transition_days < var.long_term_file_expiration_days
}

resource "null_resource" "validation_check" {
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    precondition {
      condition     = local.is_valid_retention
      error_message = "For non-dev/test environments, regular_file_expiration_days should be at least 365 days"
    }
    precondition {
      condition     = local.is_valid_transition
      error_message = "Var regular_file_transition_days should be less than regular_file_expiration_days"
    }
    precondition {
      condition     = local.is_valid_two_years
      error_message = "For non-dev/test environments, critical_file_expiration_days should be at least 790 days"
    }
    precondition {
      condition     = local.is_valid_critical_transition
      error_message = "Var critical_file_transition_days should be less than critical_file_expiration_days"
    }
    precondition {
      condition     = local.is_valid_seven_years
      error_message = "For non-dev/test environments, long_term_file_expiration_days should be at least 2556 days"
    }
    precondition {
      condition     = local.is_valid_long_term_transition
      error_message = "Var long_term_file_transition_days should be less than long_term_file_expiration_days"
    }
  }
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_ownership_controls" "primary_app_file_storage" {
  bucket   = aws_s3_bucket.primary_app_file_storage.id
  provider = aws.primary

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_acl" "primary_app_file_storage" {
  bucket   = aws_s3_bucket.primary_app_file_storage.id
  provider = aws.primary
  acl      = "private"

  depends_on = [aws_s3_bucket_ownership_controls.primary_app_file_storage]
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket" "primary_app_file_storage" {
  bucket   = "${var.environment}-${var.aws_region}-app-artifacts-app"
  provider = aws.primary

  force_destroy = var.destroy

  tags = {
    Name = "${var.environment}-${var.aws_region}-app-artifacts-app"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "primary_app_file_storage" {
  bucket   = aws_s3_bucket.primary_app_file_storage.id
  provider = aws.primary

  rule {
    id     = "authorizations"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "authorizations/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cardorders"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cardorders/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-ach"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-ach/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-company-responses"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-company-responses/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-junk-drawer"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-junk-drawer/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-master-data"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-master-data/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-past-due-aging"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-past-due-aging/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-statements"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-statements/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-transactions"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-transactions/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-out-companies"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-out-companies/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-out-transactions"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-out-transactions/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "mc-in-clearing"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "mc-in-clearing/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "visa-in-clearing"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "visa-in-clearing/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "fi-out-ach"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "fi-out-ach/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "fi-out-reports"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "fi-out-reports/"
    }

    transition {
      days          = var.critical_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.critical_file_expiration_days
    }
  }

  rule {
    id     = "statements"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "statements/"
    }

    transition {
      days          = var.critical_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.critical_file_expiration_days
    }
  }

  rule {
    id     = "financials"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "financials/"
    }

    transition {
      days          = var.critical_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.critical_file_expiration_days
    }
  }

  rule {
    id     = "statement-zips"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "statement-zips/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "outbound"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "outbound/"
    }

    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }
}

resource "aws_s3_bucket_policy" "primary_app_file_storage_bucket_policy" {
  bucket   = aws_s3_bucket.primary_app_file_storage.id
  provider = aws.primary

  policy = <<END_POLICY
{
  "Version": "2012-10-17",
  "Statement":[
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
       "Resource": "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-app/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": [
        "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-app",
        "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-app/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal":{
        "AWS": "arn:aws:iam::999999999999:role/EKS-Astronomer-WorkerNodes-prod-V-NodeInstanceRole-V2SJOS67TNM5"
      },
      "Action":[
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-app/fi-out-reports/0010/DailyTrialBalance/*",
        "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-app/fi-out-reports/0010/DailyCreditActivity/*"
      ]
    }
    ${local.netsuite_policy_primary}
  ]
}
END_POLICY
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary_app_file_storage" {
  bucket   = aws_s3_bucket.primary_app_file_storage.id
  provider = aws.primary

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "primary_app_file_storage" {
  bucket   = aws_s3_bucket.primary_app_file_storage.id
  provider = aws.primary

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "secondary_app_file_storage" {
  bucket   = aws_s3_bucket.secondary_app_file_storage.id
  provider = aws.secondary

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "secondary_app_file_storage" {
  bucket   = aws_s3_bucket.secondary_app_file_storage.id
  provider = aws.secondary
  acl      = "private"

  depends_on = [aws_s3_bucket_ownership_controls.secondary_app_file_storage]
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket" "secondary_app_file_storage" {
  bucket   = "${var.environment}-${var.replication_aws_region}-app-artifacts-app"
  provider = aws.secondary

  force_destroy = var.destroy

  tags = {
    Name = "${var.environment}-${var.replication_aws_region}-app-artifacts-app"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "secondary_app_file_storage" {
  bucket   = aws_s3_bucket.secondary_app_file_storage.id
  provider = aws.secondary

  rule {
    id     = "authorizations"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "authorizations/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cardorders"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cardorders/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-ach"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-ach/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-company-responses"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-company-responses/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-junk-drawer"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-junk-drawer/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-master-data"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-master-data/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-past-due-aging"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-past-due-aging/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-statements"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-statements/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-in-transactions"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-in-transactions/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-out-companies"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-out-companies/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "cc-out-transactions"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "cc-out-transactions/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "mc-in-clearing"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "mc-in-clearing/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "visa-in-clearing"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "visa-in-clearing/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "fi-out-ach"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "fi-out-ach/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "fi-out-reports"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "fi-out-reports/"
    }
    transition {
      days          = var.long_term_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.long_term_file_expiration_days
    }
  }

  rule {
    id     = "statements"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "statements/"
    }
    transition {
      days          = var.long_term_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.long_term_file_expiration_days
    }
  }


  rule {
    id     = "financials"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "financials/"
    }
    transition {
      days          = var.long_term_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.long_term_file_expiration_days
    }
  }

  rule {
    id     = "statement-zips"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "statement-zips/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }

  rule {
    id     = "outbound"
    status = var.include_lifecycle_rule ? "Enabled" : "Disabled"

    filter {
      prefix = "outbound/"
    }
    transition {
      days          = var.regular_file_transition_days
      storage_class = "GLACIER"
    }
    expiration {
      days = var.regular_file_expiration_days
    }
  }
}

resource "aws_s3_bucket_policy" "secondary_app_file_storage_bucket_policy" {
  bucket   = aws_s3_bucket.secondary_app_file_storage.id
  provider = aws.secondary

  policy = <<END_POLICY
{
  "Version": "2012-10-17",
  "Statement":[
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
       "Resource": "arn:aws:s3:::${var.environment}-${var.replication_aws_region}-app-artifacts-app/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": [
        "arn:aws:s3:::${var.environment}-${var.replication_aws_region}-app-artifacts-app",
        "arn:aws:s3:::${var.environment}-${var.replication_aws_region}-app-artifacts-app/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal":{
        "AWS": "arn:aws:iam::999999999999:role/EKS-Astronomer-WorkerNodes-prod-V-NodeInstanceRole-V2SJOS67TNM5"
      },
      "Action":[
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.environment}-${var.replication_aws_region}-app-artifacts-app/fi-out-reports/0010/DailyTrialBalance/*",
        "arn:aws:s3:::${var.environment}-${var.replication_aws_region}-app-artifacts-app/fi-out-reports/0010/DailyCreditActivity/*"
      ]
    }
    ${local.netsuite_policy_secondary}
  ]
}
END_POLICY
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secondary_app_file_storage" {
  bucket   = aws_s3_bucket.secondary_app_file_storage.id
  provider = aws.secondary

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_versioning" "secondary_app_file_storage" {
  bucket   = aws_s3_bucket.secondary_app_file_storage.id
  provider = aws.secondary

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "aws_s3_replication_primary_to_secondary" {
  bucket   = aws_s3_bucket.primary_app_file_storage.bucket
  provider = aws.primary

  role = aws_iam_role.app_file_storage_replication.arn

  depends_on = [
    aws_s3_bucket.primary_app_file_storage,
    aws_s3_bucket.secondary_app_file_storage,
    aws_iam_policy.app_file_storage_replication,
  ]

  rule {
    id       = "east_rep_west"
    priority = 0
    status   = "Enabled"

    delete_marker_replication {
      status = "Enabled"
    }

    filter {} # must exist for api call be valid

    source_selection_criteria {

      replica_modifications {
        status = "Enabled"
      }

      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }


    destination {
      bucket = aws_s3_bucket.secondary_app_file_storage.arn
      encryption_configuration {
        replica_kms_key_id = var.aws_kms_arn_secondary
      }

    }
  }

  dynamic "rule" {
    for_each = var.additional_replication_rules

    content {
      id       = rule.value.id
      priority = index(var.additional_replication_rules[*].id, rule.value.id) + 1
      status   = rule.value.enabled ? "Enabled" : "Disabled"

      delete_marker_replication {
        status = rule.value.delete_marker_replication ? "Enabled" : "Disabled"
      }

      destination {
        bucket = rule.value.destination.bucket_arn
        encryption_configuration {
          replica_kms_key_id = rule.value.destination.replica_kms_key_id
        }
        dynamic "metrics" {
          for_each = rule.value.destination.metrics != null ? [rule.value.destination.metrics] : []

          content {
            status = metrics.value.enabled ? "Enabled" : "Disabled"
            event_threshold {
              minutes = metrics.value.event_threshold.minutes
            }
          }
        }

        dynamic "replication_time" {
          for_each = rule.value.destination.metrics != null ? [rule.value.destination.metrics.replication_time] : []

          content {
            status = replication_time.value.enabled ? "Enabled" : "Disabled"
            time {
              minutes = replication_time.value.time.minutes
            }
          }
        }
      }

      filter {
        prefix = rule.value.prefix
      }

      source_selection_criteria {
        sse_kms_encrypted_objects {
          status = rule.value.source.sse_kms_encrypted_objects ? "Enabled" : "Disabled"
        }
      }
    }
  }
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_replication_configuration" "aws_s3_replication_secondary_to_primary" {
  bucket   = aws_s3_bucket.secondary_app_file_storage.bucket
  provider = aws.secondary

  role = aws_iam_role.app_file_storage_replication.arn

  depends_on = [
    aws_s3_bucket.primary_app_file_storage,
    aws_s3_bucket.secondary_app_file_storage,
    aws_iam_policy.app_file_storage_replication
  ]

  rule {
    id     = "west_rep_east"
    status = "Enabled"

    delete_marker_replication {
      status = "Enabled"
    }

    filter {} # must exist for api call be valid

    source_selection_criteria {
      replica_modifications {
        status = "Enabled"
      }
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket = aws_s3_bucket.primary_app_file_storage.arn
      encryption_configuration {
        replica_kms_key_id = var.aws_kms_arn_primary
      }
    }
  }
}

resource "aws_s3_bucket" "data_services_bucket" {
  bucket   = "${var.environment}-${var.aws_region}-data-services"
  provider = aws.primary

  force_destroy = var.destroy

  tags = {
    Name = "${var.environment}-${var.aws_region}-data-services"
  }
}

resource "aws_s3_bucket_policy" "data_services_bucket_policy" {
  count = length(var.data_services_s3_access_policies) > 0 ? 1 : 0

  bucket = aws_s3_bucket.data_services_bucket.id
  policy = data.aws_iam_policy_document.data_services_access[0].json
}

data "aws_iam_policy_document" "data_services_access" {
  count = length(var.data_services_s3_access_policies) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = var.data_services_s3_access_policies

    content {
      actions = statement.value.actions
      resources = [
        for resource in statement.value.resources : replace(resource, "<bucket-arn>", "arn:aws:s3:::${var.environment}-${var.aws_region}-data-services")
      ]
      principals {
        type        = "AWS"
        identifiers = [statement.value.principal]
      }
      sid = statement.value.statement_id
      dynamic "condition" {
        for_each = statement.value.conditions != null ? statement.value.conditions : []

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_s3_bucket_versioning" "data_services_bucket" {
  bucket   = aws_s3_bucket.data_services_bucket.id
  provider = aws.primary

  versioning_configuration {
    status = "Enabled"
  }
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_server_side_encryption_configuration" "data_services_bucket" {
  bucket   = aws_s3_bucket.data_services_bucket.id
  provider = aws.primary

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = "arn:aws:kms:${var.aws_region}:${var.aws_account_number}:key/${var.data_services_kms_key_id}"
      sse_algorithm     = "aws:kms"
    }
  }
}