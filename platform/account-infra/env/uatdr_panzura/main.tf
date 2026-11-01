# Locals 
# ===============================================
locals {
  environment              = "uat"
  region                   = "us-west-2"

  domain_name              = "secure.apps.example.com"
}

# Locals
# =================================================
locals {
  region_keys = {
    "us-east-1"      = "UE1"
    "us-west-2"      = "UW2"
  }
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
    key    = "coreplatform-account-infrastructure/uatdr_panzura/terraform.tfstate"
    region = "us-west-2"
  }
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_panzura" {
  source = "../../modules/coreplatform-panzura"

  panzura_endpoint          = "files.${local.domain_name}"

  account_infra_state_bucket = "finserv-coreplatformdr-tfstates"
  account_infra_state_key    = "coreplatform-account-infrastructure/${local.environment}dr/terraform.tfstate"
  account_infra_state_region = "${local.region}"
}
