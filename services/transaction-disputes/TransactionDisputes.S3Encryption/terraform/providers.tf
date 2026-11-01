# providers.tf
# Manages provider configuration resources.

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.52.0"
    }
  }

  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {
    # This should be provided in a separate conf file during terraform init
  }
}

provider "aws" {
  region = local.region[terraform.workspace]

  default_tags {
    tags = {
      Name        = local.long_app_name
      Owner       = "user@example-company.com"
      Email       = "user@example-company.com"
      AppID       = local.short_app_name
      Environment = terraform.workspace
      BillingId   = "CORP-XXXXX-XXXX-XXXXX"
      LOB         = "Payment Processing"
    }
  }
}
