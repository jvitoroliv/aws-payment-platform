# Variables
# ===============================================

# Locals 
# ===============================================
locals {
  environment             = "prod"
  region                  = "us-west-2"
  vpc_id                  = "vpc-0example000000001"
  DBPrimary_CIDR          = "10.99.98.186/32"
  DBSecondary_CIDR        = "10.99.97.195/32"
  DBPrimaryReadOnly_CIDR  = "10.99.99.163/32"
  DBDisasterRecovery_CIDR = "10.99.101.240/32"
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
    key    = "coreplatform-account-infrastructure/proddr_nacl_killswitch/terraform.tfstate"
    region = "us-west-2"
  }
}


# Core Modules
# ===============================================
# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_nacl_killswitch" {
  source = "../../modules/coreplatform-nacl-killswitch"
  
  # vpc-level
  region                  = "${local.region}"
  environment             = "${local.environment}"
  vpc_id                  = "${local.vpc_id}"
  DBPrimary_CIDR          = "${local.DBPrimary_CIDR}"
  DBSecondary_CIDR        = "${local.DBSecondary_CIDR}"
  DBPrimaryReadOnly_CIDR  = "${local.DBPrimaryReadOnly_CIDR}"
  DBDisasterRecovery_CIDR = "${local.DBDisasterRecovery_CIDR}"
}

