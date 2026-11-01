# global.tf
# Part of the global Terraform configuration module.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "s3_replication" {
  source = "../../../modules/tag-s3-replication"

  aws_account_number       = var.aws_account_number
  aws_kms_arn_primary      = "arn:aws:kms:us-east-1:999999999999:key/a61fc80a-3cf3-4aa3-9334-0ef30982541e"
  aws_kms_arn_secondary    = "arn:aws:kms:us-west-2:999999999999:key/a3e88d1d-8cdd-4e40-bf10-3968c8626675"
  aws_region               = var.aws_region
  data_services_kms_key_id = "mrk-00000000000000000000000000000000"
  environment              = var.environment
  replication_aws_region   = var.replication_aws_region

  # Prod only: These replication rules are in addition to the cross region replication and replicate reports to the data-services S3 bucket
  additional_replication_rules = [
    {
      id                        = "data-services-s3-trialbalance-replication-rule"
      delete_marker_replication = false
      prefix                    = "fi-out-reports/0010/DailyTrialBalance/"
      enabled                   = true
      destination = {
        bucket_arn         = "arn:aws:s3:::prod-us-east-1-data-services"
        replica_kms_key_id = "arn:aws:kms:us-east-1:999999999999:key/mrk-00000000000000000000000000000000"
      }
      source = {
        sse_kms_encrypted_objects = true
      }
    },
    {
      id                        = "data-services-s3-creditactivity-replication-rule"
      delete_marker_replication = false
      prefix                    = "fi-out-reports/0010/DailyCreditActivity/"
      enabled                   = true
      destination = {
        bucket_arn         = "arn:aws:s3:::prod-us-east-1-data-services"
        replica_kms_key_id = "arn:aws:kms:us-east-1:999999999999:key/mrk-00000000000000000000000000000000"
      }
      source = {
        sse_kms_encrypted_objects = true
      }
    },
    {
      id                        = "data-services-s3-visa-replication-rule"
      delete_marker_replication = false
      prefix                    = "visa-in-clearing/"
      enabled                   = true
      destination = {
        bucket_arn         = "arn:aws:s3:::prod-us-east-1-data-services"
        replica_kms_key_id = "arn:aws:kms:us-east-1:999999999999:key/mrk-00000000000000000000000000000000"
      }
      source = {
        sse_kms_encrypted_objects = true
      }
    },
    {
      id                        = "data-services-s3-mastercard-replication-rule"
      delete_marker_replication = false
      prefix                    = "mc-in-clearing/"
      enabled                   = true
      destination = {
        bucket_arn         = "arn:aws:s3:::prod-us-east-1-data-services"
        replica_kms_key_id = "arn:aws:kms:us-east-1:999999999999:key/mrk-00000000000000000000000000000000"
        metrics = {
          enabled          = true
          event_threshold  = { minutes = 15 }
          replication_time = { enabled = true, time = { minutes = 15 } }
        }
      }
      source = {
        sse_kms_encrypted_objects = true
      }
    }
  ]

  data_services_key_policies = [
    {
      action       = ["kms:*"]
      effect       = "Allow"
      resource     = ["*"]
      principal    = ["arn:aws:iam::999999999999:root"]
      statement_id = "Enable IAM User Permissions"
    },
    {
      action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      effect   = "Allow"
      resource = ["*"]
      principal = [
        "arn:aws:iam::999999999999:root",
        "arn:aws:iam::999999999999:role/tf-iam-role-prod-app-file-storage-replication",
        "arn:aws:iam::999999999999:role/SAMLDevOpsUserAccess",
        "arn:aws:iam::999999999999:role/SAMLSupportUser",
        "arn:aws:iam::999999999999:role/SAMLAdministratorAccess",
      ]
      statement_id = "Allow use of the key"
    },
    {
      action = ["kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"]
      condition = {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }

      effect   = "Allow"
      resource = ["*"]
      principal = [
        "arn:aws:iam::999999999999:role/SAMLDevOpsUserAccess",
        "arn:aws:iam::999999999999:role/SAMLAdministratorAccess",
        "arn:aws:iam::999999999999:role/SAMLSupportUser",
        "arn:aws:iam::999999999999:root",
        "arn:aws:iam::999999999999:role/tf-iam-role-prod-app-file-storage-replication",
      ]
      statement_id = "Allow attachment of persistent resources"
    },
    {
      action    = ["kms:Decrypt"]
      effect    = "Allow"
      resource  = ["*"]
      principal = ["arn:aws:iam::999999999999:user/finserv-jitterbit-user"]
    },
  ]

  data_services_s3_access_policies = [
    {
      actions      = ["s3:GetObject"]
      principal    = "arn:aws:iam::999999999999:role/EKS-Astronomer-WorkerNodes-prod-V-NodeInstanceRole-V2SJOS67TNM5"
      resources    = ["<bucket-arn>/fi-out-reports/0010/DailyTrialBalance/*"]
      statement_id = "AllowDataServicesTrialBalance"
    },
    {
      actions      = ["s3:GetObject"]
      principal    = "arn:aws:iam::999999999999:role/EKS-Astronomer-WorkerNodes-prod-V-NodeInstanceRole-V2SJOS67TNM5"
      resources    = ["<bucket-arn>/fi-out-reports/0010/DailyCreditActivity/*"]
      statement_id = "AllowDataServicesCreditActivity"
    },
    {
      actions   = ["s3:GetObject"]
      principal = "arn:aws:iam::999999999999:user/finserv-jitterbit-user"
      resources = ["<bucket-arn>/visa-in-clearing/*", "<bucket-arn>/mc-in-clearing/*"]
    },
    {
      actions   = ["s3:ListBucket"]
      principal = "arn:aws:iam::999999999999:user/finserv-jitterbit-user"
      resources = ["<bucket-arn>"]
      conditions = [
        {
          test     = "StringLike"
          variable = "s3:prefix"
          values   = ["visa-in-clearing/*", "mc-in-clearing/*"]
        }
      ]
    }
  ]

  providers = {
    aws.primary   = aws.primary_region
    aws.secondary = aws.replication_region
  }
}
