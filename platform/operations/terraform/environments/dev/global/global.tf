# global.tf
# Manages global Terraform configuration resources.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "s3_replication" {
  source = "../../../modules/tag-s3-replication"

  aws_account_number           = var.aws_account_number
  aws_kms_arn_primary          = "arn:aws:kms:us-east-1:999999999999:key/3cd84f3f-c4a1-4a9b-bd7c-dc7a0df09c60"
  aws_kms_arn_secondary        = "arn:aws:kms:us-west-2:999999999999:key/bb563777-2878-465d-88b1-8a3939db8a18"
  aws_region                   = var.aws_region
  data_services_kms_key_id     = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  environment                  = var.environment
  replication_aws_region       = var.replication_aws_region
  regular_file_expiration_days = 90
  regular_file_transition_days = 30

  critical_file_expiration_days = 90
  critical_file_transition_days = 30

  long_term_file_expiration_days = 90
  long_term_file_transition_days = 30

  data_services_s3_access_policies = [
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
