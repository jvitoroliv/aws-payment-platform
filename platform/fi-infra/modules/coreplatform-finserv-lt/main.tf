# Variables
# ===============================================

# branch and buildnumber
# Type constraint catches misuse at plan time.
variable "branch"      { }
variable "buildnumber"                  { }
variable "kpk"                          { default = "TEST" }

# dependencies
# Input validation ensures callers provide sane values.
variable "account_infra_state_bucket"   { }
variable "account_infra_state_key"      { }
variable "account_infra_state_region"   { }


# vpc-level
variable "region"                       { }
# Defaults are production-safe; override per environment.
variable "region_key"                   { }
variable "environment"                  { }
variable "fi_name"                      { }
variable "fi_name_public"               { }
variable "fi_config"                    { }   # FI used in the UserData startup script for the config transforms, this will always be a real FI, e.g., corp or sample_fi
variable "fi_short_key"                 { default = "W" } 
# Documented in the module README with accepted ranges.
variable "ebs_kms_alias"                { }
variable "s3_kms_alias"                 { }
variable "sqs_kms_alias"                { }
variable "partition"                    { }
variable "account_id"                   { }

# instances
variable "key_name"                     { }
variable "ebs_optimized"                { default = true }
variable "transform_flags"              { default = "" }

# tags
variable "tag_billingid"                { default = "platform-XXXX" }
variable "tag_compliance"               { default = "PCI-CDE" }
variable "tag_dataclass"                { default = "Confidential" }
variable "tag_drtier"                   { default = "2" }
variable "tag_lob"                      { default = "Payment Processing" }
variable "tag_owner"                    { default = "user@example-company.com" }
variable "tag_projectname"              { default = "coreplatform" }
variable "tag_approle"                  { default = "app" }
variable "tag_app_id"                   { default = "APP_44819" } # I looked this up in cherwell
variable "tag_ostype"                   { default = "Windows" }
variable "tag_application"              { default = "coreplatform" }


# fax server
variable "fax_instance_type"            { default = "r5.large" }
variable "fax_min_instances"            { default = 2 }
variable "fax_max_instances"            { default = 2 }
variable "fax_default_cooldown"         { default = 300 }
variable "fax_volume_size"              { default = 100 }
variable "fax_lb_ingress_cidr"          { type = "list" default = ["10.0.0.0/8"] }
variable "fax_lb_internal"              { default = true }
variable "fax_lb_listener_port"         { default = 80 }
variable "fax_lb_listener_proto"        { default = "HTTP" }
variable "fax_lb_certificate_arn"       { default = "" }
variable "fax_lb_ssl_policy"            { default = "" }
variable "fax_lb_access_logging"        { default = true }
variable "fax_ASGOFF_tag"               { default = "off=(M-F,21);tz=est" }
variable "fax_ASGON_tag"                { default = "on=(M-F,7);tz=est" }
variable "fax_site_id"                  { default = "100" }
variable "fax_asg_suspend_policy"       { type = "list", default = [] }
variable "gpo_params"                   { default = "ROLE-ENC-GPOSupplemental-IIS" }

# processor server
variable "processor_instance_type"      { default = "r5.large" }
variable "processor_min_instances"      { default = 2 }
variable "processor_max_instances"      { default = 2 }
variable "processor_default_cooldown"   { default = 300 }
variable "processor_volume_size"        { default = 100 }
variable "processor_lb_ingress_cidr"    { type = "list" default = ["10.0.0.0/8"] }
variable "processor_lb_internal"        { default = true }
variable "processor_lb_listener_port"   { default = 80 }
variable "processor_lb_listener_proto"  { default = "HTTP" }
variable "processor_lb_certificate_arn" { default = "" }
variable "processor_lb_ssl_policy"      { default = "" }
variable "processor_lb_access_logging"  { default = true }
variable "processor_ASGOFF_tag"         { default = "off=(M-F,21);tz=est" }
variable "processor_ASGON_tag"          { default = "on=(M-F,7);tz=est" }
variable "processor_site_id"            { default = "300" }
variable "processor_asg_suspend_policy" { 
                                          type = "list",
                                          default = [] 
                                        }

# web application firewall CIDRs
# Defaults work for standard deployments.
variable "waf_ingress_cidr"             { type = "list" default = ["10.0.0.0/8"] }
variable "qualys_public_ingress_cidr"   { type = "list" default = ["10.0.0.0/8"] }

# DNS/AD
variable "dns_domain"                   { }
variable "tier1_oupath"                 { }
variable "tier2_oupath"                 { }
variable "dnsServerAddresses"           { default = "" }

# common additional variables
variable "unhealthy_alarm_arn"          { default = "" }
variable "splunk_egress_cidr"           { 
                                          type = "list",
                                          default = ["10.94.2.111/32"] 
                                        }

variable "app_server_lb_sg_id"          { }

#cpm backup tag for the cattles
variable "cpm_backup_tag"               { default = "no-backup" }

# PARTNER MQ config values used by MQ Client
variable "partner_mq_startup_script_params" { default = "" }

# Datadog Monitoring default in prod, proddr and uat
variable "datadog_enable"               { default = "true" }


#Providers
# =================================================
provider "null" {
  version = "2.1.2"
}
provider "aws" {
  version = "2.70.4"
  region = "${var.region}"
}
provider "template" {
  version = "2.2.0"
}
# Locals
# =================================================
locals {
  fi_config         = "finserv"   # startup script config transform is run for this FI

  region_keys = {
    "us-east-1"      = "UE1"
    "us-west-2"      = "UW2"
  }

  env_keys = {
    "dev"   = "D"
    "uat"   = "U"
    "stage" = "S"
    "demo"  = "C"
    "prod"  = "P"
    "qa"    = "Q"
  }

  short_region_keys = {
    "us-east-1" = "E"
    "us-west-2" = "W"
  }

  region_dns_suffix = "${lower(var.region) == "us-east-1" ? "" : "-${lower(lookup(local.region_keys, var.region))}"}"
}


# Datasources
# =================================================

data "terraform_remote_state" "account_infrastructure" {
  backend = "s3"
  config = {
    bucket = "${var.account_infra_state_bucket}"
    key    = "${var.account_infra_state_key}"
    region = "${var.account_infra_state_region}"
  }
}

data "aws_vpc" "vpc" {
  id = "${data.terraform_remote_state.account_infrastructure.vpc_id}"
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Public"
  }
}

data "aws_kms_alias" "ebs_key" {
  name = "${var.ebs_kms_alias}"
}

data "aws_kms_alias" "s3_key" {
  name = "${var.s3_kms_alias}"
}

data "aws_kms_alias" "sqs_key" {
  name = "${var.sqs_kms_alias}"
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


# Module Calls
# =================================================

# -- Common Tags --
# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "cpt_tags" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//cpt_tags"

  billingid   = "${var.tag_billingid}"
  compliance  = "${var.tag_compliance}"
  dataclass   = "${var.tag_dataclass}"
  drtier      = "${var.tag_drtier}"
  environment = "${var.environment}"
  finame      = "${var.fi_name}"
  lob         = "${var.tag_lob}"
  owner       = "${var.tag_owner}"
  projectname = "${var.tag_projectname}"
  approle     = "${var.tag_approle}"
  app_id      = "${var.tag_app_id}"
  ostype      = "${var.tag_ostype}"
  application = "${var.tag_application}"
}

# -- Fax disposition server --
data "aws_ami" "fax_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-CorePlatformIIS-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

module "fax_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-fax"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  subnet_ids                      = [ "${split(",", var.fax_lb_internal ? join(",", data.aws_subnet_ids.private.ids) : join(",", concat(data.aws_subnet_ids.public.ids, list(""))))}" ]
  #subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  tags                            = "${merge(module.cpt_tags.tags, map("drtier", "1","cas-patching-utc","cattle"))}"
  tags                            = "${merge(module.cpt_tags.tags, map("drtier", "1","cas-patching-utc","cattle"))}"
  lb_internal                     = "${var.fax_lb_internal}"
  lb_listener_port                = "${var.fax_lb_listener_port}"
  lb_listener_proto               = "${var.fax_lb_listener_proto}"
  lb_certificate_arn              = "${var.fax_lb_certificate_arn}"
  lb_ssl_policy                   = "${var.fax_lb_ssl_policy}"
  lb_access_logging               = "${var.fax_lb_access_logging}"
  bucket_name                     = "finserv-ue1-cpt-encaccesslogging-${var.environment}"
  lb_ingress_cidr                 = "${var.fax_lb_ingress_cidr}"
  target_protocol                 = "HTTP"
  target_group_port               = "80"
  healthcheck_enabled             = true
  healthcheck_interval            = 30
  healthcheck_path                = "/css.htm"
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 5
  healthcheck_healthy_threshold   = 3
  healthcheck_unhealthy_threshold = 3
  healthcheck_matcher             = "200"
  unhealthy_alarm_sns_topic_arn   = "${var.unhealthy_alarm_arn}"
  use_default_ingress_sg_rule     = true
  use_default_egress_sg_rule      = false # override outbound sg rules below
}

resource "aws_security_group_rule" "fax_server_lb_outbound_fax" {
  security_group_id        = "${module.fax_server_lb.lb_sg_id}"
  description              = "Outbound to fax server instances"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.fax_server_asg.cluster_sg_id}"
}

data "aws_iam_policy_document" "fax_policy_document" {

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/finserv/Web*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*",
    ]
  }

  statement {
    sid = "s3"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      # resources required for the instance artifact refresh
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*"
    ]
  }
}

# Shared security group for multiple servers (twilio/efax)
module "fax_server_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg_lt"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-fax"
  fi_name                         = ""
  fi_list                         = "FINSERV,ClientBank"
  environment                     = "${var.environment}"
  hostname                        = "A${lookup(local.region_keys, var.region)}FAXSVRS000${lookup(local.env_keys, var.environment)}"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  key_name                        = "${var.key_name}"
  image_id                        = "${data.aws_ami.fax_ami.id}"
  instance_type                   = "${var.fax_instance_type}"
  ebs_optimized                   = "${var.ebs_optimized}"
  volume_size                     = "${var.fax_volume_size}"
  min_size                        = "${var.fax_min_instances}"
  max_size                        = "${var.fax_max_instances}"
  default_cooldown                = "${var.fax_default_cooldown}"
  ingress_cidr                    = "${var.fax_lb_ingress_cidr}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  target_group_arns                = ["${module.fax_server_lb.lb_tg_arn}"]
  ASGON_tag                       = "${var.fax_ASGON_tag}"
  ASGOFF_tag                      = "${var.fax_ASGOFF_tag}"
  tags                            = "${merge(module.cpt_tags.tags,map("drtier","1","cas-patching-utc","cattle"))}"
  asg_tags                        = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}", "${map("key", "cas-patching-utc", "value", "cattle", "propagate_at_launch", true)}"]
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.fax_policy_document.json}"
  startup_path                    = "C:\\CoreService\\FAX"
  startup_script                  = "startup.ps1"
  startup_script_params           = "branch,${var.branch}"
  site_id                         = "${var.fax_site_id}"
  health_check_grace_period       = "1200"
  health_check_type               = "ELB"
  ad_password_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                      = "${var.dns_domain}"
  datadog_enable                  = "${var.datadog_enable}"
  oupath                          = "${var.tier1_oupath}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  suspended_processes             = ["${var.fax_asg_suspend_policy}"]
  lb_sgs                          = ["${module.fax_server_lb.lb_sg_id}"]
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups      = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}"
  ]
  uselifecyclehook                = "true"
  gpo_params                      = "${var.gpo_params}"
  transform_flags                 = "${var.transform_flags}"
}

# Allow processor server to access app server LB
resource "aws_security_group_rule" "app_server_lb_inbound_fax" {
  security_group_id        = "${var.app_server_lb_sg_id}"
  description              = "Inbound from fax server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.fax_server_asg.cluster_sg_id}"
}

# -- processor server ASG --
data "aws_ami" "processor_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-CorePlatformIIS-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"]
  }
}

data "aws_iam_policy_document" "processor_policy_document" {

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/finserv/Web*",
	    "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*",
    ]
  },

   statement {
    sid = "kms1"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptTo",
      "kms:ReEncryptFrom",
    ]

    resources = [
      "${data.aws_kms_alias.sqs_key.arn}",
      "${data.aws_kms_alias.sqs_key.target_key_arn}",
    ]
  },

  statement {
    sid = "kms2"

    actions = [
      "kms:ListKeys",
      "kms:ListAliases"
    ]

    resources = ["*"]
  }
}

module "processor_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-proc"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  subnet_ids                      = [ "${split(",", var.processor_lb_internal ? join(",", data.aws_subnet_ids.private.ids) : join(",", concat(data.aws_subnet_ids.public.ids, list(""))))}" ]
  #subnet_ids                     = ["${data.aws_subnet_ids.private.ids}"]
  tags                            = "${merge(module.cpt_tags.tags, map("drtier", "1","cas-patching-utc","cattle"))}"
  tags                            = "${merge(module.cpt_tags.tags, map("drtier", "1","cas-patching-utc","cattle"))}"
  lb_internal                     = "${var.processor_lb_internal}"
  lb_listener_port                = "${var.processor_lb_listener_port}"
  lb_listener_proto               = "${var.processor_lb_listener_proto}"
  lb_certificate_arn              = "${var.processor_lb_certificate_arn}"
  lb_ssl_policy                   = "${var.processor_lb_ssl_policy}"
  lb_access_logging               = "${var.processor_lb_access_logging}"
  bucket_name                     = "finserv-ue1-cpt-encaccesslogging-${var.environment}"
  lb_ingress_cidr                 = "${var.processor_lb_ingress_cidr}"
  target_protocol                 = "HTTP"
  target_group_port               = 80
  healthcheck_enabled             = true
  healthcheck_interval            = 90
  healthcheck_path                = "/css.htm"
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 30
  healthcheck_healthy_threshold   = 3
  healthcheck_unhealthy_threshold = 10
  healthcheck_matcher             = "200"
  unhealthy_alarm_sns_topic_arn   = "${var.unhealthy_alarm_arn}"
  use_default_ingress_sg_rule     = true
  use_default_egress_sg_rule      = false # override outbound sg rules below
}

resource "aws_security_group_rule" "proc_server_lb_outbound_proc" {
  security_group_id        = "${module.processor_server_lb.lb_sg_id}"
  description              = "Outbound to proc server instances"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.processor_server_asg.cluster_sg_id}"
}

module "processor_server_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg_lt"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-proc"
  fi_name                         = ""
  fi_list                         = "FINSERV,ClientBank"
  environment                     = "${var.environment}"
  hostname                        = "A${lookup(local.region_keys, var.region)}PRCSVRS000${lookup(local.env_keys, var.environment)}"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  key_name                        = "${var.key_name}"
  image_id                        = "${data.aws_ami.processor_ami.id}"
  instance_type                   = "${var.processor_instance_type}"
  ebs_optimized                   = "${var.ebs_optimized}"
  volume_size                     = "${var.processor_volume_size}"
  min_size                        = "${var.processor_min_instances}"
  max_size                        = "${var.processor_max_instances}"
  default_cooldown                = "${var.processor_default_cooldown}"
  ingress_cidr                    = "${var.processor_lb_ingress_cidr}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  target_group_arns                = ["${module.processor_server_lb.lb_tg_arn}"]
  ASGON_tag                       = "${var.processor_ASGON_tag}"
  ASGOFF_tag                      = "${var.processor_ASGOFF_tag}"
  tags                            = "${merge(module.cpt_tags.tags,map("drtier","1","cas-patching-utc","cattle"))}"
  asg_tags                        = ["${module.cpt_tags.autoscaling_tags}","${map("key", "cpm backup", "value", "${var.cpm_backup_tag}", "propagate_at_launch", true)}", "${map("key", "cas-patching-utc", "value", "cattle", "propagate_at_launch", true)}"]
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.processor_policy_document.json}"
  startup_path                    = "C:\\CoreService\\PROC"
  startup_script                  = "startup.ps1"
  startup_script_params           = "branch,${var.branch}"
  site_id                         = "${var.processor_site_id}"
  health_check_grace_period       = "1200"
  health_check_type               = "ELB"
  ad_password_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.tier1_oupath}"
  datadog_enable                  = "${var.datadog_enable}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  suspended_processes             = ["${var.processor_asg_suspend_policy}"]
  lb_sgs                          = ["${module.processor_server_lb.lb_sg_id}"]
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups      = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}"
  ]
  uselifecyclehook                = "true"
  gpo_params                      = "${var.gpo_params}"
  transform_flags                 = "${var.transform_flags}"
}

# Allow processor server to access app server LB
resource "aws_security_group_rule" "app_server_lb_inbound_processor" {
  security_group_id        = "${var.app_server_lb_sg_id}"
  description              = "Inbound from processor server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.processor_server_asg.cluster_sg_id}"
}

# -- DNS --
data "aws_route53_zone" "group_zone" {
  name         = "${data.terraform_remote_state.account_infrastructure.domain_name}."
  private_zone = true
}

# fax DNS
data "aws_lb" "fax_lb" {
  arn  = "${module.fax_server_lb.lb_id}"
}

resource "aws_route53_record" "fax_dns_record" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "shrd-fax${local.region_dns_suffix}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.fax_lb.dns_name}"
    zone_id                = "${data.aws_lb.fax_lb.zone_id}"
    evaluate_target_health = true
  }
}

# processor DNS
data "aws_lb" "processor_lb" {
  arn  = "${module.processor_server_lb.lb_id}"
}

resource "aws_route53_record" "processor_dns_record" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "shrd-processor${local.region_dns_suffix}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.processor_lb.dns_name}"
    zone_id                = "${data.aws_lb.processor_lb.zone_id}"
    evaluate_target_health = true
  }
}

# Outputs
# =================================================
output "fi_name_public" { value = "${var.fi_name_public}" }