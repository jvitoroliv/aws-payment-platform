# provider.tf
# Part of the provider Terraform configuration module.

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      owner       = "user@example-company.com"
      project     = "TAG"
      lob         = "Payment Processing"
      managedby   = "Terraform"
      billingid   = "CORP-XXXXX-XXXX-XXXXX"
      repository  = "shared-terraform"
      environment = var.environment
    }
  }
}

# State backend and provider version constraints.
# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {

  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }

  }
  required_version = ">=1.6"
}
