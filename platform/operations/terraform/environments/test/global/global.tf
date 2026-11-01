# global.tf
# Manages global Terraform configuration resources.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "s3_replication" {
  source                   = "../../../modules/tag-s3-replication"
  aws_region               = var.aws_region
  environment              = var.environment
  aws_account_number       = var.aws_account_number
  replication_aws_region   = var.replication_aws_region
  aws_kms_arn_primary      = "arn:aws:kms:us-east-1:999999999999:key/3cd84f3f-c4a1-4a9b-bd7c-dc7a0df09c60"
  aws_kms_arn_secondary    = "arn:aws:kms:us-west-2:999999999999:key/bb563777-2878-465d-88b1-8a3939db8a18"
  data_services_kms_key_id = "aaaaaaaa-bbbb-cccc-dddd-ffffffffffff"

  regular_file_expiration_days = 90
  regular_file_transition_days = 30

  critical_file_expiration_days = 90
  critical_file_transition_days = 30

  long_term_file_expiration_days = 90
  long_term_file_transition_days = 30

  providers = {
    aws.primary   = aws.primary_region
    aws.secondary = aws.replication_region
  }
}

