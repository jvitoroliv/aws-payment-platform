# Variables
# ===============================================
# Locals 
# ===============================================
locals {
  environment         = "prod"
  region              = "us-west-2"
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
# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {
    bucket = "finserv-coreplatformdr-tfstates"
    key    = "coreplatform-account-infrastructure/proddr_lambdas/terraform.tfstate"
    region = "us-west-2"
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