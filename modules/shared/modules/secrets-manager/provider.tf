# provider.tf
# Manages provider Terraform configuration resources.

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  required_version = ">= 1.6.5"
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
