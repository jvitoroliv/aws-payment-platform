# Locals
# ===============================================
locals {
  fi_name                        = "shrd"
  fi_short_key                   = "S"
  ado_agent_fi_list              = "finserv"  # comma delimited list of FIs, e.g., finserv,partner_a
  environment                    = "uat"
  region                         = "us-west-2"
  vpc_id                         = "vpc-0example000000001"
  account_id                     = "111111111103"
    
  ad_directory_name              = "secure.finservglobal.example.com"
  oupath                         = "OU=FINSERV,OU=UAT,OU=UTIL,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM"

  ingress_cidr                   = ["10.0.0.0/8"]

  instance_type                  = "m5.large"
  volume_size                    = "200"

  ontime_tag                     = "on=(n/a)"
  offtime_tag                    = "off=(n/a)"
  patchgroup1                    = "WIN_UAT_0"
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
    key    = "coreplatform-account-infrastructure/uatdr_adobuild/terraform.tfstate"
    region = "us-west-2"
  }
}


# Core Modules
# ===============================================
# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_adobuild" {
  source = "../../modules/coreplatform-adobuild"

  account_infra_state_bucket  = "finserv-coreplatformdr-tfstates"
  account_infra_state_key     = "coreplatform-account-infrastructure/uatdr/terraform.tfstate"
  account_infra_state_region  = "${local.region}"

  dns_domain                  = "${local.ad_directory_name}"
  oupath                      = "${local.oupath}"

  region                      = "${local.region}"
  environment                 = "${local.environment}"
  vpc_id                      = "${local.vpc_id}"
  fi_name                     = "${local.fi_name}"
  fi_short_key                = "${local.fi_short_key}"
  ado_agent_fi_list           = "${local.ado_agent_fi_list}"
  ebs_kms_alias               = "alias/coreplatform-stage-uw2-ebs-kms-key"
  account_id                  = "${local.account_id}"
  
  key_name                    = "coreplatform-${local.environment}dr"
  instance_type               = "${local.instance_type}"
  volume_size                 = "${local.volume_size}"
  ec2on_tag                   = "${local.ontime_tag}"
  ec2off_tag                  = "${local.offtime_tag}"
  patchgroup1                 = "${local.patchgroup1}"
  ingress_cidr                = "${local.ingress_cidr}"
}
