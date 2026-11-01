# provider.tf
# Part of the provider Terraform configuration module.

# State backend and provider version constraints.
# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.28.0"
    }

  }
  required_version = ">=1.6"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      owner      = "user@example-company.com"
      project    = "TAG"
      lob        = "Payment Processing"
      managedby  = "Terraform"
      billingid  = "CORP-XXXXX-XXXX-XXXXX"
      repository = "shared-terraform"
    }
  }
}