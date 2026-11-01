# provider.tf
# Part of the provider Terraform configuration module.

# State backend and provider version constraints.
# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.98.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.0"
    }

  }
  required_version = ">=1.6"
}
