# locals.tf
# Manages local value computations resources.

locals {
  netsuite_svc_account = "tag-${var.aws_account_number == "222222222222" ? "prod" : "test"}-s3-netsuite"

  netsuite_policy_primary = var.environment == "stage" ? "" : <<EOT
    ,{
      "Effect": "Allow",
      "Principal":{
        "AWS": "arn:aws:iam::${var.aws_account_number}:user/${local.netsuite_svc_account}"
      },
      "Action":[
        "s3:*"
      ], 
      "Resource": [
        "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-app/fi-out-reports/0010/DailyFiLedgerReport",
        "arn:aws:s3:::${var.environment}-${var.aws_region}-app-artifacts-app/fi-out-reports/0010/DailyFiLedgerReport/*"
      ]
    }
EOT

  netsuite_policy_secondary = var.environment == "stage" ? "" : <<EOT
     ,{
      "Effect": "Allow",
      "Principal":{
        "AWS": "arn:aws:iam::${var.aws_account_number}:user/${local.netsuite_svc_account}"
      },
      "Action":[
        "s3:*"
      ], 
      "Resource": [
        "arn:aws:s3:::${var.environment}-${var.replication_aws_region}-app-artifacts-app/fi-out-reports/0010/DailyFiLedgerReport",
        "arn:aws:s3:::${var.environment}-${var.replication_aws_region}-app-artifacts-app/fi-out-reports/0010/DailyFiLedgerReport/*"
      ]
    }
EOT

  # Because the replication destination buckets can vary, this local is built to contain a list of all the S3 bucket ARNs that will be used as replication destinations.
  # This list is then used to grant permissions to the S3 bucket replication IAM Role so it can replicate to all of the destination S3 buckets.
  s3_replication_destination_bucket_arns = concat(
    [
      aws_s3_bucket.primary_app_file_storage.arn,
      aws_s3_bucket.secondary_app_file_storage.arn,
    ],
    distinct(var.additional_replication_rules[*].destination.bucket_arn)
  )
}
