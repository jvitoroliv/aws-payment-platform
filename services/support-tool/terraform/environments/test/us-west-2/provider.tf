# provider.tf
# Manages provider Terraform configuration resources.

provider "aws" {
  region  = var.aws_region
  version = "~> 2.8"
}

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  required_version = "v0.12.20"
  backend s3 {
    encrypt        = true
    bucket         = "corp-subprod-terraform-state-store-us-west-2"
    dynamodb_table = "tag-subprod-state-store"
    key            = "support-test.tfstate"
    region         = "us-west-2"
  }
  required_providers {
    datadog  = "2.5"
    null     = "2.1"
    template = "2.1"
    aws      = "2.67"
  }
}

provider "datadog" {
  api_key = var.dd_api_key
  app_key = var.dd_app_key
}