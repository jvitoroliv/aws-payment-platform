# iam.tf
# Part of the IAM roles and policies module.

resource "aws_iam_role" "app_file_storage_replication" {
  name = "tf-iam-role-${var.environment}-app-file-storage-replication"

  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

POLICY
}

resource "aws_iam_policy" "app_file_storage_replication" {
  name = "tf-iam-role-policy-${var.environment}-app-file-storage-replication"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetReplicationConfiguration", "s3:ListBucket"],
      "Resource": ${jsonencode(local.s3_replication_destination_bucket_arns)}
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ],
      "Resource": ${jsonencode(formatlist("%s/*", local.s3_replication_destination_bucket_arns))}
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Resource": ${jsonencode(formatlist("%s/*", local.s3_replication_destination_bucket_arns))}
    },
    {
      "Effect": "Deny",
      "Action": [
        "s3:*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Resource": ${jsonencode(formatlist("%s/*", local.s3_replication_destination_bucket_arns))}
    }
  ]
}
POLICY
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "app-file-storage-replication" {
  role       = aws_iam_role.app_file_storage_replication.name
  policy_arn = aws_iam_policy.app_file_storage_replication.arn
}

resource "aws_kms_key_policy" "data_services_key_policy" {
  count  = var.environment == "prod" ? 1 : 0
  key_id = var.data_services_kms_key_id
  policy = data.aws_iam_policy_document.kms_data_services_access.json
}

data "aws_iam_policy_document" "kms_data_services_access" {
  dynamic "statement" {
    for_each = var.data_services_key_policies

    content {
      actions   = statement.value.action
      effect    = statement.value.effect
      resources = statement.value.resource
      sid       = statement.value.statement_id

      dynamic "condition" {
        for_each = statement.value.condition == null ? [] : [statement.value.condition]
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }

      principals {
        identifiers = statement.value.principal
        type        = "AWS"
      }
    }
  }
}