# main.tf
# Manages primary resource definitions resources.

locals {
  environment         = "dev"
  region              = "us-east-1"
  vpc_id              = "vpc-0example000000001"
  ad_directory_name   = "ad.dev.encawsad.test"
  private_hosted_zone = "coreplatformdev.ue1.finservglobal.example.com"
  domain_name         = "dev.platform.example.com"
  ontime_tag          = "on=(n/a)" ## "on=(M-F,7);tz=est" #TODO when we want to pick this project back up, we'll want to put this back
  offtime_tag         = "off=(M-F,21);tz=est"
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
    key    = "coreplatform-account-infrastructure/controlm/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

# Control M 
# ===============================================
# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "controlm" {
  source = "../deployment-upgrade"
  ami_id          = "ami-0dad700c3acbc46f2"
  region          = "${local.region}"
  environment     = "${local.environment}"
  vpc_id          = "${local.vpc_id}"
  ebs_kms_alias   = "alias/coreplatform-${local.environment}-ue1-ebs-kms-key"
  key_name        = "coreplatform-${local.environment}"
  domain_name     = "${local.domain_name}"
}

# Outputs
# ===============================================
output "vpc_id"                 { value = "${local.vpc_id}" }
output "domain_name"            { value = "${local.domain_name}" }
output "ctm_primary_ip"         { value = "${module.controlm.ctm_primary_ip}" }
output "ctm_secondary_ip"       { value = "${module.controlm.ctm_secondary_ip}" }
