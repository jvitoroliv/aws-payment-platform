# provider.tf
# Manages provider Terraform configuration resources.

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  required_version = ">=1.6"
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {
    encrypt        = true
    bucket         = "corp-subprod-terraform-state-store-us-east-1"
    dynamodb_table = "tag-subprod-state-store"
    key            = "test-test-harness.tfstate"
    region         = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.28.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      owner       = "user@example-company.com"
      project     = "TAG"
      lob         = "Payment Processing"
      managedby   = "Terraform"
      billingid   = "CORP-XXXXX-XXXX-XXXXX"
      repository  = "ps-tag-test-harness"
      environment = var.alt_env_name != "" ? var.alt_env_name : var.environment
    }
  }
}