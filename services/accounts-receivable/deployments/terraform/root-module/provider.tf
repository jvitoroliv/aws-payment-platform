# provider.tf
# Manages provider Terraform configuration resources.

# State backend and provider version constraints.
# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {}
  required_providers {
    aiven = {
      source  = "aiven/aiven"
      version = "4.13.0"
    }
    aws = {
      source  = "hashicorp/aws"
      # version = ">=5.33.0"
      version = "~> 5.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
  required_version = ">=1.6"
}

provider "aiven" {
  api_token = data.aws_secretsmanager_secret_version.aiven_api_token.secret_string
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      owner      = "user@example-company.com"
      project    = "TAG"
      lob        = "Payment Processing"
      managedby  = "Terraform"
      billingid  = "CORP-XXXXX-XXXX-XXXXX"
      repository = "ps-tag-accounts-receivabe"
    }
  }
}
