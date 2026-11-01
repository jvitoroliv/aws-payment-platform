# Variables
# ===============================================

# kpk
# Input validation ensures callers provide sane values.
variable "kpk"         { default = "TEST" } # Later change to UAT when the uat env becomes a PCI env

# Locals 
# ===============================================
locals {
  environment               = "uat"
  aws_environment           = "stage"
  region                    = "us-west-2"
  vpc_id                    = "vpc-0example000000001"
  ad_directory_name         = "secure.finservglobal.example.com"
  private_hosted_zone       = "coreplatformuat.uw2.finservglobal.example.com"
  domain_name               = "stage.platform.example.com"
  ontime_tag                = "on=(n/a)"
  offtime_tag               = "off=(n/a)"
  patchgroup1               = "WIN_UAT_0"
  patchgroup2               = "WIN_UAT_1"
  oupath                    = "OU=FINSERV,OU=UAT,OU=WEB,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM"
  db_startup_script_params  = "db_backups_s3_bucket,finserv-coreplatform-backups-uat"
  ebs_kms_alias             = "alias/coreplatform-stage-uw2-ebs-kms-key"
  disable_api_termination   = true
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
    key    = "coreplatform-account-infrastructure/uatdr_pet_cerberus_restore/terraform.tfstate" # This is an intentionally duplicated key for the restore pipeline to avoid state confusion and allows this pipeline to be run prior to a real restore
    region = "us-west-2"
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
module "coreplatform_cerberus" {
  source = "../../modules/coreplatform-cerberus"

  # KPK
  kpk         = "${var.kpk}"

  # vpc-level
  region          = "${local.region}"
  environment     = "${local.environment}"
  vpc_id          = "${local.vpc_id}"
  ebs_kms_alias   = "${local.ebs_kms_alias}"

  # dns
  private_hosted_zone = "${local.private_hosted_zone}"
  public_hosted_zone  = "${local.public_hosted_zone}"
  dns_domain          = "${local.ad_directory_name}"
  domain_name					= "${local.domain_name}"

  # db / sql server
  key_name                              = "coreplatform-${local.environment}dr"
  instance_count                        = 0
  cerberus_instance_type                = "r5a.xlarge"
  cerberus_ec2on_tag                    = "${local.ontime_tag}"
  cerberus_ec2off_tag                   = "${local.offtime_tag}" 
  patchgroup1                           = "${local.patchgroup1}"
  patchgroup2                           = "${local.patchgroup2}"

  cerberus_volume_size                  = 200
  cerberus_lb_ingress_cidr              = ["10.0.0.0/8"]
  cerberus_lb_internal                  = true
  cerberus_lb_listener_port             = 443
  cerberus_lb_listener_proto            = "TLS"
  cerberus_sg_monitoring_listener_port  = 1443
	cerberus_sg_monitoring_ingress_cidr 	= ["10.94.1.162/32"]
	cerberus_sg_DEF_ingress_cidr 					= ["198.51.100.40/32"]
	cerberus_sg_api_listener_port					= 10001
  #cerberus_ASGOFF_tag                  = "${local.offtime_tag}"
  #cerberus_ASGON_tag                   = "${local.ontime_tag}"
  oupath                                = "${local.oupath}"
  cerberus_startup_script_params        = "${local.db_startup_script_params}"
  disable_api_termination         			= "${local.disable_api_termination}"
	cerberus_lb_ssl_policy								= "ELBSecurityPolicy-TLS13-1-2-2021-06"
	cerberus_lb_certificate_arn 					= "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
	cerberus_sg_pws_ingress_cidr					= ["198.51.100.170/32", "198.51.100.171/32", "198.51.100.172/32"]
	cerberus_sg_f5_ingress_cidr						= ["172.16.1.251/32", "172.16.1.199/32", "172.16.1.250/32"]
	cerberus_sg_bat3_ingress_cidr					= ["198.51.100.38/32"]
	cerberus_sg_bat1_ingress_cidr					= ["198.51.100.40/32"]
  cerberus_sg_netskope1_ingress_cidr		= ["10.94.1.218/32"]
	cerberus_sg_netskope2_ingress_cidr		= ["10.94.2.121/32"]
	cerberus_sg_netskope3_ingress_cidr		= ["10.94.0.172/32"]

  # account state
  account_infra_state_bucket = "finserv-coreplatformdr-tfstates"
  account_infra_state_key    = "coreplatform-account-infrastructure/${local.environment}dr/terraform.tfstate"
  account_infra_state_region = "${local.region}"
}


# Outputs
# ===============================================
output "vpc_id"                 { value = "${local.vpc_id}" }