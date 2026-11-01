# global.tf
# Part of the global Terraform configuration module.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "s3_replication" {
  source                   = "../../../modules/tag-s3-replication"
  aws_region               = var.aws_region
  environment              = var.environment
  aws_account_number       = var.aws_account_number
  replication_aws_region   = var.replication_aws_region
  aws_kms_arn_primary      = "arn:aws:kms:us-east-1:999999999999:key/15b624a8-d117-4b1b-be72-da0cbe4148a8" # aws/s3
  aws_kms_arn_secondary    = "arn:aws:kms:us-west-2:999999999999:key/1fedb575-6fde-481c-a96c-251ac7b2cb8e" # aws/s3
  data_services_kms_key_id = "aaaaaaaa-bbbb-cccc-dddd-ffffffffffff"
  providers = {
    aws.primary   = aws.primary_region
    aws.secondary = aws.replication_region
  }
}

