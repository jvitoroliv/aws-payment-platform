# provider.tf
# Part of the provider Terraform configuration module.

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.28"
    }
    aiven = {
      source = "aiven/aiven"
      version = "~> 3.8.1"
    }
  }
  required_version = "~> 1.6"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      billingid = "CORP-XXXXX-XXXX-XXXXX"
      owner     = "user@example-company.com"
    }
  }
}

provider "aiven" {
  api_token = data.aws_secretsmanager_secret_version.aiven_api_token.secret_string
}
