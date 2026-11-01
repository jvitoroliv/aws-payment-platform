# Locals
# ===============================================
locals {
  fi_name           = "shrd"
  fi_short_key      = "S"
  ado_agent_fi_list = "finserv,partner_a"              # comma delimited list of FIs, e.g., finserv,partner_a
  environment       = "prod"
  region            = "us-west-2"
  vpc_id            = "vpc-0example000000001"
  account_id        = "111111111106"

  ad_directory_name = "secure.finservglobal.example.com"
  oupath            = "OU=FINSERV,OU=PROD,OU=UTIL,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM"
  ingress_cidr = ["10.0.0.0/8"]

  instance_type = "m5.xlarge"
  volume_size   = "200"

  ontime_tag  = "on=(n/a)"
  offtime_tag = "off=(n/a)"
  patchgroup1 = "WIN_PROD_0"
  fi_list     = "finserv,partner_a"
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
    key    = "coreplatform-account-infrastructure/proddr_adobuild_asg/terraform.tfstate"
    region = "us-west-2"
  }
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_adobuild-asg" {
  source = "../../modules/coreplatform-adobuild-asg"

  account_infra_state_bucket = "finserv-coreplatformdr-tfstates"
  account_infra_state_key    = "coreplatform-account-infrastructure/proddr/terraform.tfstate"
  account_infra_state_region = "${local.region}"

  dns_domain = "${local.ad_directory_name}"
  oupath     = "${local.oupath}"

  region            = "${local.region}"
  vpc_id            = "${local.vpc_id}"
  environment       = "${local.environment}"
  fi_name           = "${local.fi_name}"
  fi_short_key      = "${local.fi_short_key}"
  ado_agent_fi_list = "${local.ado_agent_fi_list}"
  fi_list           = "${local.fi_list}"
  ebs_kms_alias     = "alias/coreplatform-${local.environment}-uw2-ebs-kms-key"
  account_id        = "${local.account_id}"

  key_name      = "coreplatform-${local.environment}dr"
  instance_type = "${local.instance_type}"
  volume_size   = "${local.volume_size}"
  ec2on_tag     = "${local.ontime_tag}"
  ec2off_tag    = "${local.offtime_tag}"
  patchgroup1   = "${local.patchgroup1}"
  ingress_cidr  = "${local.ingress_cidr}"
}
