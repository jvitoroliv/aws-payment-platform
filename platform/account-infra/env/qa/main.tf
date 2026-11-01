# Variables
# ===============================================

# kpk
variable "kpk"         { default = "TEST" }

# Locals 
# ===============================================
locals {
  environment         = "qa"
  fi_list             = "FINSERV,Partner-Bank-A"
  region              = "us-east-1"
  account_id          = "111111111105"
  vpc_id              = "vpc-0example000000001"
  ad_directory_name   = "secure.finservglobal.example.com"
  private_hosted_zone = "coreplatformqa.ue1.finservglobal.example.com"
  public_hosted_zone  = "qa-public.platform.example.com"
  domain_name         = "qa.platform.example.com"
  ontime_tag          = "on=(M-F,7);tz=est"
  offtime_tag         = "off=(M-F,21);tz=est"
  ses_s3_bucket       = "finserv-coreplatform-emails-qa"
  oupath              = "OU=FINSERV,OU=QAT,OU=UTIL,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM"
  partner_mq_port         = 1418
  partner_mq_publish_port = 1414
  partner_mq_egress_cidr  = ["10.0.0.0/8"] # Not a valid PARTNER MQ address, not accessing PARTNER MQ in this env
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
    key    = "coreplatform-account-infrastructure/qa/terraform.tfstate"
    region = "us-east-1"
  }
}


# Secrets are in the FI\env script because the username can not be calculated using
# interpolation in the fi module
# ===============================================
# Secret: ServiceUsers/{env}/ALLFIS/Db
variable "db_service_account_secret_value" {
  default = {
    username = "secure\\z-ENC-DB-QA-FINSERV-SV"
    # The password will populated with this value when the secret is created 
    # but will not be updated after the secret has been manually modified
    password = "WILL_BE_SET_MANUALLY" 
  }

  type = "map"
}


# Core Modules
# ===============================================
# Module sourced from internal registry — pin version to prevent unexpected changes
module "coreplatform_account" {
  source = "../../modules/coreplatform-account"
  
  # kpk
  kpk         = "${var.kpk}"

  # vpc-level
  region          = "${local.region}"
  environment     = "${local.environment}"
  fi_list         = "${local.fi_list}"
  vpc_id          = "${local.vpc_id}"
  ebs_kms_alias   = "alias/coreplatform-${local.environment}-ue1-ebs-kms-key"

  # dns
  private_hosted_zone   = "${local.private_hosted_zone}"
  public_hosted_zone    = "${local.public_hosted_zone}"
  dns_domain            = "${local.ad_directory_name}"
  oupath                = "${local.oupath}"
  # dnsServerAddresses    = ""

  #instances
  key_name                      = "coreplatform-${local.environment}"
  dbtools_instance_type         = "r5a.xlarge"
  dbtools_ec2on_tag             = "${local.ontime_tag}"
  dbtools_ec2off_tag            = "${local.offtime_tag}"  
  dbtools_volume_size           = 200
  dbtools_datadog_check_params  = "datadog_tcp_check_server_filter,AUE1BATSVR*Q"
  adtools_instance_type         = "r5a.large"
  adtools_ec2on_tag             = "${local.ontime_tag}"
  adtools_ec2off_tag            = "${local.offtime_tag}"
  adtools_volume_size           = 200
  adtools_count                 = 0
  
  # jobdb
  jobdb_read_capacity       = 5
  jobdb_write_capacity      = 5

  # hosted zone
  domain_name               = "${local.domain_name}"
  s3_bucket_ses             = "${local.ses_s3_bucket}"

  # qualys and pentesting
  allow_qualys_scans        = "true"
  qualys_ingress_cidr       = ["10.94.193.212/32","10.97.1.240/32","10.97.1.175/32"] #us-east-1 qualys scanner
  # SQL diagnostic_cidr
  sql_diagnostic_cidr       =  ["10.94.1.162/32","10.94.1.81/32"]

  # partner mq on-prem
  partner_mq_port               = "${local.partner_mq_port}"
  partner_mq_publish_port       = "${local.partner_mq_publish_port}"
  partner_mq_egress_cidr        = "${local.partner_mq_egress_cidr}"
}


# Outputs
# ===============================================
output "vpc_id"                               { value = "${local.vpc_id}" }
output "domain_name"                          { value = "${local.domain_name}" }
output "private_hosted_zone_id"               { value = "${module.coreplatform_account.private_hosted_zone_id}" }
output "sql_diagnostic_sg_id"                 { value = "${module.coreplatform_account.sql_diagnostic_sg_id}" }
output "outbound_email_sg_id"                 { value = "${module.coreplatform_account.outbound_email_sg_id}" }
output "inbound_winrm_sg_id"                  { value = "${module.coreplatform_account.inbound_winrm_sg_id}" }
output "outbound_partner_mq_sg_id"                { value = "${module.coreplatform_account.outbound_partner_mq_sg_id}" }
output "basic_server_connectivity_sg_id"      { value = "${module.coreplatform_account.basic_server_connectivity_sg_id}" }
output "jobs_sg_id"                           { value = "${module.coreplatform_account.jobs_sg_id}" }
output "outbound_sftp_sg_id"                  { value = "${module.coreplatform_account.outbound_sftp_sg_id}" }
output "outbound_third_party_services_sg_id"  { value = "${module.coreplatform_account.outbound_third_party_services_sg_id}" }

## DEPRECATED BY coporate tools sg, remove when references to this are gone
output "outbound_activedirectory_sg_id"       { value = "${module.coreplatform_account.outbound_activedirectory_sg_id}" }
output "qualys_sg_id"                         { value = "${module.coreplatform_account.qualys_sg_id}" }
output "rdp_access_sg_id"                     { value = "${module.coreplatform_account.rdp_access_sg_id}" }
