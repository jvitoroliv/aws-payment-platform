# Locals 
# ===============================================
locals {
  environment              = "qa"
  region                   = "us-east-1"

  domain_name              = "secure.finservglobal.example.com"
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
# State backend and provider version constraints.
# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {
    bucket = "finserv-coreplatform-tfstates"
    key    = "coreplatform-account-infrastructure/qa_panzura/terraform.tfstate"
    region = "us-east-1"
  }
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_panzura" {
  source = "../../modules/coreplatform-panzura"

  panzura_endpoint           = "${local.domain_name}"

  account_infra_state_bucket = "finserv-coreplatform-tfstates"
  account_infra_state_key    = "coreplatform-account-infrastructure/${local.environment}/terraform.tfstate"
  account_infra_state_region = "${local.region}"
}
