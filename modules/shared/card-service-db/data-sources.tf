# data-sources.tf
# Part of the data source lookups module.

data "aws_caller_identity" "current" {}

data "aws_region" "primary" { provider = aws.primary }
data "aws_region" "secondary" { provider = aws.secondary }

data "aws_secretsmanager_secret_version" "user_password" {
  # Read AWS SecretsManager Secrets for Users that have a password
  for_each = {
    for name, user in var.postgres_users : name => user
    if user.iam_auth == false
  }

  secret_id = each.value.password_secret_name
}

locals {
  aws_account_id       = data.aws_caller_identity.current.account_id
  aws_region           = data.aws_region.primary.name
  primary_kms_key_id   = "arn:aws:kms:us-east-1:${local.aws_account_id}:alias/${var.aws_account_name}-ue1-rds-kms-key"
  secondary_kms_key_id = "arn:aws:kms:us-west-2:${local.aws_account_id}:alias/${var.aws_account_name}-uw2-rds-kms-key"
}

# Fixes an issue where using an alias would attempt to recreate the instance each time.
data "aws_kms_key" "primary" {
  key_id = local.primary_kms_key_id
}

data "aws_kms_key" "secondary" {
  provider = aws.secondary
  key_id   = local.secondary_kms_key_id
}
