# Variables
# ===============================================

variable "instance_type"                { default = "r5a.xlarge" }
variable "instance_count"               { default = 1 }
variable "ingress_cidr"                 { type = "list" }
variable "ec2on_tag"                    { default = "on=(M-F,7);tz=est" }
variable "ec2off_tag"                   { default = "off=(M-F,21);tz=est" }
variable  "patchgroup1"                   {default = "n/a"}
# Type constraint catches misuse at plan time.
variable "volume_size"                  { default = 300 }
variable "disable_api_termination"      { default = true }

# DNS/AD
variable "dns_domain"                   { }
variable "oupath"                       { }
variable "dnsServerAddresses"           { default = "" }

# dependencies
variable "account_infra_state_bucket"   { }
variable "account_infra_state_key"      { }
# Input validation ensures callers provide sane values.
variable "account_infra_state_region"   { }

# vpc-level
variable "region"                       { }
variable "environment"                  { }
variable "fi_name"                      { }
# Documented in the module README with accepted ranges.
variable "fi_short_key"                 { } 
variable "ebs_kms_alias"                { }

# sns topic
variable "sns_unhealthy_instance_topic" { default = "CorePlatform-LoadBalancer-UnhealthyInstances" }

# instances
variable "key_name"                     { }

# tags
variable "tag_billingid"                { default = "platform-XXXX" }
# Defaults are production-safe; override per environment.
variable "tag_compliance"               { default = "PCI-CDE" }
variable "tag_dataclass"                { default = "Confidential" }
variable "tag_drtier"                   { default = "3" }
variable "tag_lob"                      { default = "Payment Processing" }
variable "tag_owner"                    { default = "user@example-company.com" }
variable "tag_projectname"              { default = "coreplatform" }
variable "tag_approle"                  { default = "app" }
variable "tag_app_id"                   { default = "coreplatform" }
variable "tag_ostype"                   { default = "Windows" }
variable "tag_application"              { default = "coreplatform" }

# load balancer
variable "ssrs_lb_ingress_cidr"       { type = "list" default = ["10.0.0.0/8"] }
variable "ssrs_lb_internal"           { default = true }
variable "ssrs_lb_listener_port"      { default = 80 }
variable "ssrs_lb_listener_proto"     { default = "HTTP" }
variable "ssrs_lb_certificate_arn"    { default = "" }
variable "lb_bucket_name"               { default = ""}
# other
variable "ebs_optimized"              { default = true }
variable "gpo_params"                 { default = "ROLE-ENC-GPOSupplemental-IIS" }
variable "cpm_backup_tag"             { default = "no-backup" }

variable "waf_ingress_cidr"           { type = "list" default = [] }
variable "qualys_public_ingress_cidr" { type = "list" default = [] }


# Locals
# =================================================
locals {
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

data "aws_kms_alias" "ebs_key" {
  name = "${var.ebs_kms_alias}"
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


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


# SSRS
data "aws_ami" "ssrs_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2012-SSRS-ami*"]
  }
}

data "aws_iam_policy_document" "ssrs_policy_document" {
  statement {
      sid = "secretsmanager"

      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
      ]
      resources = [
        "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*",
        "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
      ]
    }
}

# -- Unhealthy Instance Topic --
module "unhealthy_instance_topic" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//sns_topic"
  
  name   = "${upper(var.fi_name)}-${var.sns_unhealthy_instance_topic}"
}

module "ssrs_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-ssrs"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  tags                            = "${module.cpt_tags.tags}"
  lb_internal                     = "${var.ssrs_lb_internal}"
  lb_listener_port                = "${var.ssrs_lb_listener_port}"
  lb_listener_proto               = "${var.ssrs_lb_listener_proto}"
  lb_certificate_arn              = "${var.ssrs_lb_certificate_arn}"
  lb_ingress_cidr                 = "${var.ssrs_lb_ingress_cidr}"
  bucket_name                     = "${var.lb_bucket_name}"
  target_protocol                 = "HTTP"
  target_group_port               = "80"
  healthcheck_enabled             = true
  healthcheck_interval            = 30
  healthcheck_path                = "/"
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 5
  healthcheck_healthy_threshold   = 5
  healthcheck_unhealthy_threshold = 2
  healthcheck_matcher             = "200"
  unhealthy_alarm_sns_topic_arn   = "${module.unhealthy_instance_topic.topic_arn}"
  use_default_ingress_sg_rule     = false # override inbound sg rules below
  use_default_egress_sg_rule      = false # override outbound sg rules below
}

resource "aws_security_group_rule" "ssrs_server_lb_outbound_ssrs" {
  security_group_id        = "${module.ssrs_server_lb.lb_sg_id}"
  description              = "Outbound to SSRS server instances"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.ssrs_asg.instance_sg_id}"
}

resource "aws_security_group_rule" "ssrs_server_lb_inbound_waf" {
  count = "${length(var.waf_ingress_cidr) > 0 ? 1 : 0}"

  security_group_id        = "${module.ssrs_server_lb.lb_sg_id}"
  description              = "Inbound from WAF"
  type                     = "ingress"
  from_port                = "${var.ssrs_lb_listener_port}"
  to_port                  = "${var.ssrs_lb_listener_port}"
  protocol                 = "tcp"
  cidr_blocks              = ["${var.waf_ingress_cidr}"]
}

# Least-privilege: only the ports required by the service are open.
resource "aws_security_group_rule" "ssrs_server_lb_inbound_qualys" {
  count = "${length(var.qualys_public_ingress_cidr) > 0 ? 1 : 0}"

  security_group_id        = "${module.ssrs_server_lb.lb_sg_id}"
  description              = "Inbound from Qualys"
  type                     = "ingress"
  from_port                = "${var.ssrs_lb_listener_port}"
  to_port                  = "${var.ssrs_lb_listener_port}"
  protocol                 = "tcp"
  cidr_blocks              = ["${var.qualys_public_ingress_cidr}"]
}

module "ssrs_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-ssrs"
  hostname                   = "A${lookup(local.region_keys, var.region)}SSRSRV${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  ami                        = "${data.aws_ami.ssrs_ami.id}"
  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                     = "${data.aws_vpc.vpc.id}"
  instance_type              = "${var.instance_type}"
  instance_count             = "${var.instance_count}"
  key_name                   = "${var.key_name}"
  tags                       = "${module.cpt_tags.tags}"
  ec2_tags                   = "${map("cpm backup", var.cpm_backup_tag)}"
  fi_name                    = "" # note: no FI specified here intentionally
  environment                = "${var.environment}"
  volume_size                = "${var.volume_size}"
  ec2on_tag                  = "${var.ec2on_tag}"
  ec2off_tag                 = "${var.ec2off_tag}"
  patchgroup                 = "${var.patchgroup1}"
  ebs_kms_key_id             = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  aws_partition_name         = "${data.aws_partition.current.partition}"
  aws_region_name            = "${data.aws_region.current.name}"
  aws_region_abbr            = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id             = "${data.aws_caller_identity.current.account_id}"
  dns_domain                 = "${var.dns_domain}"
  oupath                     = "${var.oupath}"
  disable_api_termination    = "${var.disable_api_termination}"
  splunk_egress_cidr         = ["${var.ingress_cidr}"]
  default_egress_cidr        = ["${data.aws_vpc.vpc.cidr_block}"]
  startup_path               = ""
  startup_script             = ""  # no startup script
  iam_policy_override_json   = "${data.aws_iam_policy_document.ssrs_policy_document.json}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  additional_security_groups = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}"
  ]
  gpo_params                 = "${var.gpo_params}"
  ebs_optimized              = "${var.ebs_optimized}"
}

# Health check configuration is service-specific.
# Thresholds tuned based on observed startup time in production.
resource "aws_lb_target_group_attachment" "ssrs_target_group_attachment" {
  target_group_arn         = "${module.ssrs_server_lb.lb_tg_arn}"
  target_id                = "${element(module.ssrs_asg.instance_id, 0)}"
  port                     = 80
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group_rule" "ssrs_server_inbound_lb" {
  security_group_id        = "${module.ssrs_asg.instance_sg_id}"
  description              = "Inbound HTTP from LB"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.ssrs_server_lb.lb_sg_id}"
}

# Note: These rules are already being added in the finserv_prod main.tf because they already exist in prod 
# and we don't want to run this code in prod again. If this gets run for a non-prod env, these rules
# will be added successfully to the dbaccess sg created in the coreplatform-fi main.tf
# Database access security group
data "aws_security_group" "dbaccess_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-dbaccess-sg"
}

resource "aws_security_group_rule" "dbaccess_ssrs_sg_rule" {
  security_group_id        = "${data.aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from SSRS server"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${module.ssrs_asg.instance_sg_id}"
}

resource "aws_security_group_rule" "dbaccess_ssrs_sqlbrowser_sg_rule" {
  security_group_id        = "${data.aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from SSRS server for SQL browser"
  type                     = "ingress"
  from_port                = 1434
  to_port                  = 1434
  protocol                 = "udp"
  source_security_group_id = "${module.ssrs_asg.instance_sg_id}"
}

# -- DNS --
data "aws_route53_zone" "app_zone" {
  name         = "${data.terraform_remote_state.account_infrastructure.domain_name}."
  private_zone = true
}

data "aws_lb" "ssrs_lb" {
  arn = "${module.ssrs_server_lb.lb_id}"
}

resource "aws_route53_record" "ssrs_dns_record" {
  zone_id = "${data.aws_route53_zone.app_zone.zone_id}"
  name    = "ssrs"  # note: no FI specified here intentionally
  type    = "A"

  alias {
    name                   = "${data.aws_lb.ssrs_lb.dns_name}"
    zone_id                = "${data.aws_lb.ssrs_lb.zone_id}"
    evaluate_target_health = false
  }
}


# Outputs
# =================================================
output "ssrs_server_lb_id"    { value = "${module.ssrs_server_lb.lb_id}" }
output "ssrs_server_lb_sg_id" { value = "${module.ssrs_server_lb.lb_sg_id}" }
