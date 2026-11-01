# Variables
# ===============================================

# kpk
variable "kpk"         { default = "TEST" } # Later change to UAT when the uat env becomes a PCI env

# Locals 
# ===============================================
locals {
  environment               = "demo"
  aws_environment           = "demo"
  region                    = "us-east-1"
  account_id                = "111111111105"
  vpc_id                    = "vpc-0example000000001"
  ad_directory_name         = "secure.finservglobal.example.com"
  private_hosted_zone       = "coreplatformdemo.ue1.finservglobal.example.com"
  domain_name               = "demo.platform.example.com"
  ontime_tag                = "on=(M-F,7);tz=est"
  offtime_tag               = "off=(M-F,21);tz=est"
  patchgroup1               = "WIN_DEMO_0"
  ses_s3_bucket             = "finserv-coreplatform-emails-demo"
  oupath                    = "OU=FINSERV,OU=DEMO,OU=WEB,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM"
  disable_api_termination   = true
  db_startup_script_params = "db_backups_s3_bucket,finserv-coreplatform-backups-demo"
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
    key    = "coreplatform-account-infrastructure/demo_cerberus/terraform.tfstate"
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

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_cerberus" {
  source = "../../modules/coreplatform-cerberus"

  # KPK
  kpk         = "${var.kpk}"

  # vpc-level
  region          = "${local.region}"
  environment     = "${local.environment}"
  vpc_id          = "${local.vpc_id}"
  ebs_kms_alias   = "alias/coreplatform-${local.aws_environment}-ue1-ebs-kms-key"

  # dns
  private_hosted_zone = "${local.private_hosted_zone}"
  public_hosted_zone  = "${local.public_hosted_zone}"
  dns_domain          = "${local.ad_directory_name}"
  domain_name					= "${local.domain_name}"

  # db / sql server
  key_name             = "coreplatform-${local.environment}"
  cerberus_instance_type     = "r5a.xlarge"
  cerberus_ec2on_tag         = "${local.ontime_tag}"
  cerberus_ec2off_tag        = "${local.offtime_tag}"  
  patchgroup1                = "${local.patchgroup1}"
  cerberus_volume_size       = 200
  cerberus_lb_ingress_cidr   = ["10.0.0.0/8"]
  cerberus_lb_internal       = true
  cerberus_lb_listener_port  = 443
  cerberus_lb_listener_proto = "TLS"
  cerberus_sg_monitoring_listener_port  = 1443
	cerberus_sg_monitoring_ingress_cidr 	= []
	cerberus_sg_DEF_ingress_cidr 					= []
	cerberus_sg_api_listener_port					= 10001
  #cerberus_ASGOFF_tag                  = "${local.offtime_tag}"
  #cerberus_ASGON_tag                   = "${local.ontime_tag}"
  oupath                                = "${local.oupath}"
  cerberus_startup_script_params        = "${local.db_startup_script_params}"
  disable_api_termination         			= "${local.disable_api_termination}"
	cerberus_lb_ssl_policy								= "ELBSecurityPolicy-TLS13-1-2-2021-06"
	cerberus_lb_certificate_arn 					= "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
	cerberus_sg_pws_ingress_cidr					= ["10.0.0.0/8"]
	cerberus_sg_f5_ingress_cidr						= ["10.0.0.0/16"]
	cerberus_sg_bat3_ingress_cidr					= ["10.0.0.0/20"]
	cerberus_sg_bat1_ingress_cidr					= ["10.0.0.0/24"]
  cerberus_sg_netskope1_ingress_cidr		= ["10.0.0.0/26"]
	cerberus_sg_netskope2_ingress_cidr		= ["10.0.0.0/28"]
	cerberus_sg_netskope3_ingress_cidr		= ["10.0.0.0/30"]

  # account state
  account_infra_state_bucket = "finserv-coreplatform-tfstates"
  account_infra_state_key    = "coreplatform-account-infrastructure/${local.environment}/terraform.tfstate"
  account_infra_state_region = "${local.region}"
}


# Outputs
# ===============================================
output "vpc_id"                 { value = "${local.vpc_id}" }
output "domain_name"            { value = "${local.domain_name}" }
