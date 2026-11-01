
# Locals 
# ===============================================
locals {
  ebs_kms_alias            = "alias/coreplatform-demo-ue1-ebs-kms-key"
  environment              = "demo"
  region                   = "us-east-1"
  vpc_id                   = "vpc-0example000000001"
  oupath                   = "OU=FINSERV,OU=DEMO,OU=UTIL,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM"
  fsx_administrators_group = "PERM-D-FSx-CorePlatform_QA"
  fsx_storage_capacity     = "100"
  throughput_capacity      = "32"
  dns_ips                  = ["10.94.1.77", "10.94.5.87"]  # the IP addresses of the VPC DNS servers
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
# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {
    bucket = "finserv-coreplatform-tfstates"
    key    = "coreplatform-account-infrastructure/demo_fsx/terraform.tfstate"
    region = "us-east-1"
  }
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_fsx" {
  source = "../../modules/coreplatform-fsx"

  name                       = "${lower(lookup(local.region_keys, local.region))}-cpt-enc-${local.environment}-shrd-fsx"
  environment                = "${local.environment}"
  vpc_id                     = "${local.vpc_id}"
  ebs_kms_alias              = "${local.ebs_kms_alias}"
  fsx_administrators_group   = "${local.fsx_administrators_group}"
  oupath                     = "${local.oupath}"
  dns_ips                    = "${local.dns_ips}"
  domain_name                = "${local.domain_name}"

  fsx_storage_capacity       = "${local.fsx_storage_capacity}"
  throughput_capacity        = "${local.throughput_capacity}"

  # account state
  account_infra_state_bucket = "finserv-coreplatform-tfstates"
  account_infra_state_key    = "coreplatform-account-infrastructure/${local.environment}/terraform.tfstate"
  account_infra_state_region = "${local.region}"
}


# Outputs
# ===============================================
output "fsxwin_primary_sg_id" { value = "${module.coreplatform_fsx.fsxwin_primary_sg_id}" }
output "fsxwin_arn"           { value = "${module.coreplatform_fsx.fsxwin_arn}" }
output "fsxwin_id"            { value = "${module.coreplatform_fsx.fsxwin_id}" }
output "fsxwin_dns_name"      { value = "${module.coreplatform_fsx.fsxwin_dns_name}" }