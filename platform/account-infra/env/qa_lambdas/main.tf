# Variables
# ===============================================
# Locals 
# ===============================================
locals {
  environment         = "qa"
  region              = "us-east-1"
}


# Provider
# ===============================================
provider "aws" {
  region = "${local.region}"
}


# Backend 
# ===================================================
# NOTE: no ${local.interpolation} allowed in Backend!
# ===================================================
# State backend and provider version constraints.
# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {
    bucket = "finserv-coreplatform-tfstates"
    key    = "coreplatform-account-infrastructure/qa_lambdas/terraform.tfstate"
    region = "us-east-1"
  }
}

# Core Modules
# ===============================================
# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_lambdas" {
  source = "../../modules/coreplatform-lambdas"
  
  # vpc-level
  region          = "${local.region}"
  environment     = "${local.environment}"
}