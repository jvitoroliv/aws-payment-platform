# Variables
# ===============================================

# kpk
variable "kpk"         { default = "TEST" }

# Locals 
# ===============================================
locals {
  environment         = "dev"
  region              = "us-east-1"
  vpc_id              = "vpc-0example000000001"
  ad_directory_name   = "ad.dev.encawsad.test"
  private_hosted_zone = "coreplatformdev.ue1.finservglobal.example.com"
  domain_name         = "dev.platform.example.com"
  ontime_tag          = "on=(M-F,7);tz=est"
  offtime_tag         = "off=(M-F,21);tz=est"
  oupath              = "OU=Computers,OU=ad,DC=ad,DC=dev,DC=encawsad,DC=test"
  db_oupath           = "OU=Computers,OU=ad,DC=ad,DC=dev,DC=encawsad,DC=test"
  dnsServerAddresses  = "10.99.82.159,10.99.83.240" # the IP addresses of the VPC DNS servers
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
    key    = "coreplatform-account-infrastructure/dev_db/terraform.tfstate"
    region = "us-east-1"
  }
}


# Data Sources
# ===============================================
data "aws_vpc" "vpc" {
  id = "${local.vpc_id}"
}


# Core Modules
# ===============================================

# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_db" {
  source = "../../modules/coreplatform-db"

  # KPK
  kpk         = "${var.kpk}"

  # vpc-level
  region          = "${local.region}"
  environment     = "${local.environment}"
  vpc_id          = "${local.vpc_id}"
  ebs_kms_alias   = "alias/coreplatform-${local.environment}-ue1-ebs-kms-key"

  # dns
  private_hosted_zone   = "${local.private_hosted_zone}"
  dns_domain            = "${local.ad_directory_name}"
  dnsServerAddresses    = "${local.dnsServerAddresses}"

  # db / sql server
  key_name             = "coreplatform-${local.environment}"
  db_instance_type     = "m5.2xlarge"
  db_min_instances     = 1
  db_max_instances     = 1
  db_default_cooldown  = 300
  db_volume_size       = 2500
  db_lb_ingress_cidr   = ["10.0.0.0/8"]
  db_lb_internal       = true
  db_lb_listener_port  = 1433
  db_lb_listener_proto = "TCP"
  db_sg_listener_port  = 1433
  db_ASGOFF_tag        = "${local.offtime_tag}"
  db_ASGON_tag         = "${local.ontime_tag}"
  db_oupath            = "${local.db_oupath}"

  #hosted zone
  domain_name          = "${local.domain_name}"

  # account state
  account_infra_state_bucket = "finserv-coreplatform-tfstates"
  account_infra_state_key    = "coreplatform-account-infrastructure/${local.environment}/terraform.tfstate"
  account_infra_state_region = "${local.region}"
}


# Outputs
# ===============================================
output "vpc_id"                 { value = "${local.vpc_id}" }
output "domain_name"            { value = "${local.domain_name}" }
