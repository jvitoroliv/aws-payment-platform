# provider.tf
# Manages provider Terraform configuration resources.

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.8.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "random" {}

provider "vault" {
  address   = "https://vault.fabric.example.com/"
  namespace = "admin/tag/applications"
  auth_login_aws {
    role = "${var.environment}-aws-role"
  }
}
