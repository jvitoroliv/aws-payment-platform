# Variables
# ===============================================

# kpk
variable "kpk"         { default = "PROD" }

# Locals 
# ===============================================
locals {
  environment               = "prod"
  aws_environment           = "prod"
  region                    = "us-east-1"
  vpc_id                    = "vpc-0example000000001"
  ad_directory_name         = "secure.finservglobal.example.com"
  private_hosted_zone       = "coreplatformprod.ue1.finservglobal.example.com"
  domain_name               = "prod.platform.example.com"
  ontime_tag                = "on=(n/a)"
  offtime_tag               = "off=(n/a)"
  oupath                    = "OU=FINSERV,OU=PROD,OU=WEB,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM"
  db_startup_script_params  = "db_backups_s3_bucket,finserv-coreplatform-backups-prod"
  ebs_kms_alias             = "alias/coreplatform-prod-ue1-ebs-kms-key"
  disable_api_termination   = true
  include_default_userdata  = false
  startup_path              = "C:\\CoreService"
  startup_script            = "RestoreProcess.ps1"
  startup_script_params     = "PROD C:\\CorePlatform\\FTPServerRestoreStep1.ps1"
  include_restore_tag       = true
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
    key    = "coreplatform-account-infrastructure/prod_cerberus/terraform.tfstate"
    region = "us-east-1"
  }
}


# Data Sources
# ===============================================
data "aws_vpc" "vpc" {
  id = "${local.vpc_id}"
}

data "aws_caller_identity" "current" {}

data "aws_ami" "cerberus_primary_ami" {
  most_recent = true
  owners      = [
    "111111111114",  # central account
    "${data.aws_caller_identity.current.account_id}"  # current env account (for restore)
  ]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPM Policy AMI.instance*"]
  }

  filter {
    name = "tag:Name"
    values = ["ue1-cpt-enc-shrd-${local.environment}-cerberus-primary"]
  }
}

data "aws_ami" "cerberus_secondary_ami" {
  most_recent = true
  owners      = [
    "111111111114",  # central account
    "${data.aws_caller_identity.current.account_id}"  # current env account (for restore)
  ]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPM Policy AMI.instance*"]
  }

  filter {
    name = "tag:Name"
    values = ["ue1-cpt-enc-shrd-${local.environment}-cerberus-secondary"]
  }
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
  key_name                              = "coreplatform-${local.environment}"
  cerberus_instance_type                = "r5a.xlarge"
  cerberus_ec2on_tag                    = "${local.ontime_tag}"
  cerberus_ec2off_tag                   = "${local.offtime_tag}"  
  cerberus_volume_size                  = 200
  cerberus_lb_ingress_cidr              = ["10.0.0.0/8"]
  cerberus_lb_internal                  = true
  cerberus_lb_listener_port             = 443
  cerberus_lb_listener_proto            = "TLS"
  cerberus_sg_monitoring_listener_port  = 1443
  cerberus_sg_monitoring_ingress_cidr 	= ["10.94.1.162/32"]
  cerberus_sg_DEF_ingress_cidr 					= ["198.51.100.40/32"]
  cerberus_sg_api_listener_port					= 10001
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
  include_default_userdata              = "${local.include_default_userdata}"
  startup_path                          = "${local.startup_path}"
  startup_script                        = "${local.startup_script}"
  startup_script_params                 = "${local.startup_script_params}"
  include_restore_tag                   = "${local.include_restore_tag}"

  # account state
  account_infra_state_bucket = "finserv-coreplatform-tfstates"
  account_infra_state_key    = "coreplatform-account-infrastructure/${local.environment}/terraform.tfstate"
  account_infra_state_region = "${local.region}"

  # ami overrides
  cerberus_primary_ami_id_override    = "${data.aws_ami.cerberus_primary_ami.id}"
  cerberus_secondary_ami_id_override  = "${data.aws_ami.cerberus_secondary_ami.id}"
}


# Outputs
# ===============================================
output "vpc_id"                 { value = "${local.vpc_id}" }