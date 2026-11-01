# Variables
# =================================================
# kpk
variable "kpk"         {}

# vpc-level
variable "region"        { }
variable "vpc_id"        { }
# Type constraint catches misuse at plan time.
variable "environment"   { }
variable "ebs_kms_alias" { }


# dns
variable "dns_domain"           { }
variable "private_hosted_zone"  { }
variable "public_hosted_zone"   { }
variable "dnsServerAddresses"   { default = "" }
# Input validation ensures callers provide sane values.
variable "domain_name"          { }

# dependencies
variable "account_infra_state_bucket" { }
variable "account_infra_state_key"    { }
variable "account_infra_state_region" { }


# instances
variable "key_name"                      { }
variable "ebs_optimized"                 { default = true }
variable "instance_count"                { default = 1 }
variable "include_default_userdata"      { default = true }
variable "include_restore_tag"           { default = false }
# Documented in the module README with accepted ranges.
variable "startup_path"                  { default = "" }
variable "startup_script"                { default = "" }
variable "startup_script_params"         { default = "" }
variable "hostname_region_override"      { default = "" }

# cerberus server

variable "cerberus_instance_type"     { default = "r5a.xlarge" }
variable "cerberus_ec2on_tag"         { default = "on=(M-F,7);tz=est" }
variable "cerberus_ec2off_tag"        { default = "off=(M-F,21);tz=est" }
variable  "patchgroup1"               {default  = "n/a"}
variable  "patchgroup2"               {default  = "n/a"}
variable "cerberus_volume_size"       { default = 100 }
# Defaults are production-safe; override per environment.
variable "cerberus_lb_ingress_cidr"   { type = "list" }
variable "oupath"                     { }
variable "disable_api_termination"    { default = false }

variable "cerberus_lb_internal"                 { default = false }
variable "cerberus_lb_listener_port"            { }
variable "cerberus_lb_listener_proto"           { }
variable "cerberus_lb_certificate_arn"          { default = "" }
variable "cerberus_sg_monitoring_listener_port" { default = 1443 }
variable "cerberus_sg_monitoring_ingress_cidr"  { type = "list" }
variable "cerberus_sg_DEF_ingress_cidr"         { type = "list" }
variable "cerberus_startup_script_params"       { default = "" }
variable "cerberus_lb_ssl_policy"               { default = "" }
variable "cerberus_sg_api_listener_port"        { }
variable "cerberus_sg_pws_ingress_cidr"         { type = "list" }
variable "cerberus_sg_f5_ingress_cidr"          { type = "list" }
variable "cerberus_sg_bat3_ingress_cidr"        { type = "list" }
variable "cerberus_sg_bat1_ingress_cidr"        { type = "list" }
variable "cerberus_sg_network-proxy1_ingress_cidr"   { type = "list" }
variable "cerberus_sg_network-proxy2_ingress_cidr"   { type = "list" }
variable "cerberus_sg_network-proxy3_ingress_cidr"   { type = "list" }

# tags
variable "tag_billingid"   { default = "platform-XXXX" }
variable "tag_compliance"  { default = "PCI-CDE" }
variable "tag_dataclass"   { default = "Confidential" }
variable "tag_drtier"      { default = "2" }
variable "tag_lob"         { default = "Payment Processing" }
variable "tag_owner"       { default = "user@example-company.com" }
variable "tag_projectname" { default = "coreplatform" }
variable "tag_approle"     { default = "batch" }
variable "tag_app_id"      { default = "cerberus" }
variable "tag_ostype"      { default = "Windows" }
variable "tag_application" { default = "coreplatform" }

variable "ec2_tags_cpm_tag" {  type = "map" default = {"cpm backup" = "no-backup"}}


# Override AMI
variable "cerberus_primary_ami_id_override"    { default = "" }
variable "cerberus_secondary_ami_id_override"  { default = "" }

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

  restore_suffix = "${lower(var.region) == "us-east-1" ? "" : "-restore"}"
  region_dns_suffix = "${lower(var.region) == "us-east-1" ? "" : "-${lower(lookup(local.region_keys, var.region))}"}"
  hostname_region = "${var.hostname_region_override != "" ? var.hostname_region_override : lookup(local.region_keys, var.region)}"
}


# Datasources
# =================================================

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
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

data "aws_kms_alias" "ebs" {
  name = "${var.ebs_kms_alias}"
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "account_infrastructure" {
  backend = "s3"
  config = {
    bucket = "${var.account_infra_state_bucket}"
    key    = "${var.account_infra_state_key}"
    region = "${var.account_infra_state_region}"
  }
}


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
  lob         = "${var.tag_lob}"
  owner       = "${var.tag_owner}"
  projectname = "${var.tag_projectname}"
  approle     = "${var.tag_approle}"
  app_id      = "${var.tag_app_id}"
  ostype      = "${var.tag_ostype}"
  application = "${var.tag_application}"
}


data "aws_ami" "cerberus_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-GlobalBakery-WIN2019-ADTOOLS-ami-*"]
  }

  filter{
    name = "image-id"
    values = ["ami-0d777c38b308f6611","ami-0e0530b2a13331f9b"] # UE1 image, UW2 image
  }
}

module "cerberus_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer_network"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-cerbrus"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.public.ids}"]
  tags                            = "${module.cpt_tags.tags}"
  lb_internal                     = false
  lb_listener_port                = "${var.cerberus_lb_listener_port}"
  lb_listener_proto               = "${var.cerberus_lb_listener_proto}"
  lb_certificate_arn              = "${var.cerberus_lb_certificate_arn}"
  lb_ssl_policy                   = "${var.cerberus_lb_ssl_policy}"
  target_protocol                 = "TLS"
  target_group_port               = "443"
  healthcheck_enabled             = true
  healthcheck_interval            = 30
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "TCP"
  healthcheck_timeout             = 10
  healthcheck_healthy_threshold   = 3
  healthcheck_matcher             = ""
  healthcheck_path                = ""
}

data "aws_iam_policy_document" "cerberus_policy_document" {

  statement {
    sid = "secretsmanager"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/finserv/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/sample_fi/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/ALLFIS/Db*",
    ]
  }

    statement {
      sid     = "s3"

      actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*",
      "arn:${data.aws_partition.current.partition}:s3:::platform-backups-${var.environment}/*",
      "arn:${data.aws_partition.current.partition}:s3:::platform-backups-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::corp-platform-backups-${var.environment}/*",
      "arn:${data.aws_partition.current.partition}:s3:::corp-platform-backups-${var.environment}",
    ]
  }
}

resource "aws_security_group" "cerberus_sg-n1" {
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-cerberus-sg-n1"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"
}

# Must separate from aws_security_group to get rid of circular reference
resource "aws_security_group_rule" "API_Rule" {
  count             = "${var.instance_count}"
  type              = "ingress"
  from_port         = "${var.cerberus_sg_api_listener_port}"
  to_port           = "${var.cerberus_sg_api_listener_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${module.cerberus_instance.instance_private_ip[0]}/32", "${module.cerberus_instance_secondary.instance_private_ip[0]}/32"]
  security_group_id = "${aws_security_group.cerberus_sg-n1.id}"
  description       = "Instance IPs"
}

module "cerberus_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-cerberus-primary${local.restore_suffix}"
  hostname                   = "A${local.hostname_region}FTPSVRS001${lookup(local.env_keys, var.environment)}"
  ami                        = "${var.cerberus_primary_ami_id_override == "" ? data.aws_ami.cerberus_ami.id : var.cerberus_primary_ami_id_override}"
  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                     = "${data.aws_vpc.vpc.id}"
  instance_type              = "${var.cerberus_instance_type}"
  instance_count             = "${var.instance_count}"
  key_name                   = "${var.key_name}"
  tags                       = "${module.cpt_tags.tags}"
  ec2_tags                   = "${var.ec2_tags_cpm_tag}"
  fi_name                    = ""
  environment                = "${var.environment}"
  volume_size                = "${var.cerberus_volume_size}"
  ec2on_tag                  = "${var.cerberus_ec2on_tag}"
  ec2off_tag                 = "${var.cerberus_ec2off_tag}"
  patchgroup                 = "${var.patchgroup1}"
  ebs_kms_key_id             = "${data.aws_kms_alias.ebs.target_key_arn}"
  aws_partition_name         = "${data.aws_partition.current.partition}"
  aws_region_name            = "${data.aws_region.current.name}"
  aws_region_abbr            = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id             = "${data.aws_caller_identity.current.account_id}"
  dns_domain                 = "${var.dns_domain}"
  oupath                     = "${var.oupath}"
  splunk_egress_cidr         = ["${var.cerberus_lb_ingress_cidr}"]
  default_egress_cidr        = ["${data.aws_vpc.vpc.cidr_block}"]
  startup_path               = "${var.startup_path}"
  startup_script             = "${var.startup_script}"
  startup_script_params      = "${var.startup_script_params}"
  iam_policy_override_json   = "${data.aws_iam_policy_document.cerberus_policy_document.json}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  #dependencies              = ["${module.managed_ad.depended_on}"]
  additional_security_groups = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}",
    "${aws_security_group.cerberus_sg-n1.id}",
    "${aws_security_group.cerberus_custom_sg.id}"
  ]
  disable_api_termination    = "${var.disable_api_termination}"
  include_default_userdata   = "${var.include_default_userdata}"
}

module "cerberus_instance_secondary" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-cerberus-secondary${local.restore_suffix}"
  hostname                        = "A${local.hostname_region}FTPSVRS002${lookup(local.env_keys, var.environment)}"
  ami                             = "${var.cerberus_primary_ami_id_override == "" ? data.aws_ami.cerberus_ami.id : var.cerberus_secondary_ami_id_override}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  instance_type                   = "${var.cerberus_instance_type}"
  instance_count                  = "${var.instance_count}"
  key_name                        = "${var.key_name}"
  tags                            = "${module.cpt_tags.tags}"
  ec2_tags                        = "${var.ec2_tags_cpm_tag}"
  fi_name                         = ""
  environment                     = "${var.environment}"
  volume_size                     = "${var.cerberus_volume_size}"
  ec2on_tag                       = "${var.cerberus_ec2on_tag}"
  ec2off_tag                      = "${var.cerberus_ec2off_tag}"
  patchgroup                      = "${var.patchgroup2}"
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs.target_key_arn}"
  aws_partition_name              = "${data.aws_partition.current.partition}"
  aws_region_name                 = "${data.aws_region.current.name}"
  aws_region_abbr                 = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id                  = "${data.aws_caller_identity.current.account_id}"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.oupath}"
  splunk_egress_cidr              = ["${var.cerberus_lb_ingress_cidr}"]
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  startup_path                    = "${var.startup_path}"
  startup_script                  = "${var.startup_script}"
  startup_script_params           = "${var.startup_script_params}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.cerberus_policy_document.json}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  #dependencies                   = ["${module.managed_ad.depended_on}"]
  additional_security_groups      = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}",
    "${aws_security_group.cerberus_sg-n1.id}",
    "${aws_security_group.cerberus_custom_sg.id}"

  ]
  disable_api_termination    = "${var.disable_api_termination}"
  include_default_userdata   = "${var.include_default_userdata}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_secondary" {
  security_group_id    = "${module.cerberus_instance.instance_sg_id}"
  network_interface_id = "${module.cerberus_instance_secondary.network_interface_id}"
}

# Health check configuration is service-specific.
resource "aws_lb_target_group_attachment" "cerberus_tg_attach" {
  count = "${var.instance_count}"
  target_group_arn = "${module.cerberus_server_lb.lb_tg_arn}"
  target_id = "${module.cerberus_instance.instance_id[0]}"
  port = 443
}

resource "aws_security_group_rule" "PWS_Rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["${var.cerberus_sg_pws_ingress_cidr}"]
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
  description       = "PWS"
}

resource "aws_security_group_rule" "On_Prem_Rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["${var.cerberus_sg_f5_ingress_cidr}"]
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
  description       = "On Prem F5"
}

resource "aws_security_group_rule" "Bat3_Rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["${var.cerberus_sg_bat3_ingress_cidr}"]
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
  description       = "PR-SHRD-BAT03"
}

resource "aws_security_group_rule" "Bat1_Rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["${var.cerberus_sg_bat1_ingress_cidr}"]
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
  description       = "PR-FINSERV-BAT01"
}

resource "aws_security_group_rule" "8443_Rule" {
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "TCP"
  self              = true
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
}

resource "aws_security_group_rule" "139_Rule" {
  type              = "ingress"
  from_port         = 139
  to_port           = 139
  protocol          = "TCP"
  self              = true
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
}

# Least-privilege: only the ports required by the service are open.
resource "aws_security_group_rule" "SMB_Rule" {
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "TCP"
  self              = true
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
}

resource "aws_security_group_rule" "HTTPS_Rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
}

resource "aws_security_group_rule" "NetworkProxy1" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "TCP"
  cidr_blocks       = ["${var.cerberus_sg_network-proxy1_ingress_cidr}"]
  description       = "NetworkProxy Admin Console Connection - NetworkProxy-Publisher-Prod-USE1a-01"
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group_rule" "NetworkProxy2" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "TCP"
  cidr_blocks       = ["${var.cerberus_sg_network-proxy2_ingress_cidr}"]
  description       = "NetworkProxy Admin Console Connection - NetworkProxy-Publisher-Prod-USE1b-02"
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
}

resource "aws_security_group_rule" "NetworkProxy3" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "TCP"
  cidr_blocks       = ["${var.cerberus_sg_network-proxy3_ingress_cidr}"]
  description       = "NetworkProxy Admin Console Connection - NetworkProxy-Publisher-Prod-USE1c-03"
  security_group_id = "${module.cerberus_instance.instance_sg_id}"
}

resource "aws_security_group" "cerberus_custom_sg" {
  count = 1

  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-cerberus-custom-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = "${var.cerberus_sg_monitoring_listener_port}"
      to_port     = "${var.cerberus_sg_monitoring_listener_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.cerberus_sg_monitoring_ingress_cidr}"]
      self        = true
      description = "Inbound for monitoring server"
    },
    {
     from_port   = 0
     to_port     = 0
     protocol    = -1
     cidr_blocks = ["${var.cerberus_sg_DEF_ingress_cidr}"]
     description = "PR-FINSERV-BAT01 on-prem (DEF files)"
    }
  ]
}

data "aws_route53_zone" "group_zone" {
  name         = "${var.domain_name}"
  private_zone = true
}

resource "aws_route53_record" "cerberus_primary_dns_record" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "cerberusadmin${local.region_dns_suffix}"
  type    = "A"
  ttl     = "300"
  records = ["${coalescelist(module.cerberus_instance.instance_private_ip, list("10.0.0.0"))}"]
}

resource "aws_route53_record" "cerberus_api_dns_record" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "cerberus-api${local.region_dns_suffix}"
  type    = "A"
  ttl     = "300"
  records = ["${coalescelist(module.cerberus_instance.instance_private_ip, list("10.0.0.0"))}"]
}

resource "aws_ec2_tag" "restore_primary_tag" {
  count       = "${var.include_restore_tag}"
  resource_id = "${module.cerberus_instance.instance_id[0]}"
  key         = "Restoring"
  value       = "true"
}

resource "aws_ec2_tag" "restore_secondary_tag" {
  count       = "${var.include_restore_tag}"
  resource_id = "${module.cerberus_instance_secondary.instance_id[0]}"
  key         = "Restoring"
  value       = "true"
}