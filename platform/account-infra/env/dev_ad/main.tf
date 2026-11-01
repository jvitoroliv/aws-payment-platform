# Data Sources
# ===============================================
data "aws_vpc" "vpc" {
  id = "${local.vpc_id}"
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Private"
  }
}

# Locals 
# ===============================================
locals {
  environment              = "dev"
  region                   = "us-east-1"
  vpc_id                   = "vpc-0example000000001"
  oupath                   = "OU=Computers,OU=ad,DC=ad,DC=dev,DC=encawsad,DC=test"
  ad_directory_name        = "ad.dev.encawsad.test"
}

# Locals
# =================================================

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
    key    = "coreplatform-account-infrastructure/dev_ad/terraform.tfstate"
    region = "us-east-1"
  }
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_ad" {
  source = "../../modules/coreplatform-ad"

  vpc_id                = "${local.vpc_id}"
  subnet_ids            = ["${data.aws_subnet_ids.private.ids}"]
  ad_directory_name     = "${local.ad_directory_name}"
  oupath                = "${local.oupath}"
}
