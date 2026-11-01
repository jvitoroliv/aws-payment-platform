# Variables
# ===============================================

# branch and buildnumber
variable "branch"       { default = "Major" }
variable "buildnumber"  { default = "" }
variable "kpk"          { default = "TEST" }


# Locals 
# ===============================================
locals {
  environment                     = "dev"
  region                          = "us-east-1"
  ad_service_account_secret_value = "ad\\z-da-EncDevADjoin"
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
    key    = "coreplatform-account-infrastructure/dev_secrets/terraform.tfstate"
    region = "us-east-1"
  }
}


# Secrets are in the FI\env script because the username can not be calculated using
# interpolation in the fi module
# ===============================================
# Secret: ServiceUsers/{env}/ALLFIS/Db
variable "db_service_account_secret_value" {
  default = {
    username = "ad\\z-EncShrdDevDBUser"
    # The password will populated with this value when the secret is created 
    # but will not be updated after the secret has been manually modified
    password = "WILL_BE_SET_MANUALLY" 
  }

  type = "map"
}


# Core Modules
# ===============================================

# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_secrets" {
  source = "../../modules/coreplatform-secrets"

  environment = "${local.environment}"

  ad_service_account_secret_value = "${local.ad_service_account_secret_value}"
  db_service_account_secret_value = "${var.db_service_account_secret_value}"
}
