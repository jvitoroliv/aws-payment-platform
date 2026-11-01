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
variable "dns_domain"            { }
variable "private_hosted_zone"   { }
variable "dnsServerAddresses"    { default = "" }

# dependencies
# Input validation ensures callers provide sane values.
variable "account_infra_state_bucket" { }
variable "account_infra_state_key"    { }
variable "account_infra_state_region" { }


# instances
variable "key_name"                  { }
# Documented in the module README with accepted ranges.
variable "ebs_optimized"             { default = true }


# db server

# Defaults are production-safe; override per environment.
variable "db_min_instances"         { default = 1 }
variable "db_default_cooldown"      { default = 300 }
variable "db_max_instances"         { default = 1 }
variable "db_volume_size"           { default = 100 }
variable "db_instance_type"         { default = "r5.large" }
variable "db_lb_ingress_cidr"       { type = "list" }
variable "db_ASGOFF_tag"            { default = "off=(M-F,21);tz=est" }
variable "db_ASGON_tag"             { default = "on=(M-F,7);tz=est" }
variable "db_oupath"                { }

variable "db_lb_internal"           { }
variable "db_lb_listener_port"      { }
variable "db_lb_listener_proto"     { }
variable "db_lb_certificate_arn"    { default = "" }
variable "db_sg_listener_port"      { default = 1433 }
variable "db_startup_script_params" { default = "" }
variable "gpo_params"               { default = "ROLE-ENC-GPOSupplemental-SQL" }

variable "fi_list"					{ default = "FINSERV,ClientBank,TASKMAN,ClientMonitor" }

# hosted zone
variable "domain_name"           { }
# SES bucket name


# tags
variable "tag_billingid"    { default = "platform-XXXX" }
variable "tag_compliance"   { default = "PCI-CDE" }
variable "tag_dataclass"    { default = "Confidential" }
variable "tag_drtier"       { default = "3" }
variable "tag_lob"          { default = "Payment Processing" }
variable "tag_owner"        { default = "user@example-company.com" }
variable "tag_projectname"  { default = "coreplatform" }
variable "tag_approle"      { default = "database" }
variable "tag_app_id"       { default = "APP_44819" }
variable "tag_ostype"       { default = "Windows" }
variable "tag_application"  { default = "coreplatform" }
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

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Private"
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


data "aws_ami" "db_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-LocalBakery-WIN2019-SQL2017-${var.kpk}-ami-*"]
  }
}

module "db_server_lb" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//load_balancer_tcp"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-db"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  tags                            = "${module.cpt_tags.tags}"
  lb_internal                     = "${var.db_lb_internal}"
  lb_listener_port                = "${var.db_lb_listener_port}"
  lb_listener_proto               = "${var.db_lb_listener_proto}"
  lb_certificate_arn              = "${var.db_lb_certificate_arn}"
  lb_ingress_cidr                 = "${var.db_lb_ingress_cidr}"
  target_protocol                 = "TCP"
  target_group_port               = "1433"
  healthcheck_enabled             = true
  healthcheck_interval            = 30
  healthcheck_port                = "traffic-port"
  healthcheck_protocol            = "TCP"
  healthcheck_healthy_threshold   = 3
}

data "aws_iam_policy_document" "db_policy_document" {

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
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/clientbank/App*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ServiceUsers/${var.environment}/ALLFIS/Db*",
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ActiveKeys/*"

    ]
  }

  statement {
    sid     = "s3"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::platform-backups-${var.environment}/*",
      "arn:aws:s3:::platform-backups-${var.environment}",
      #special dumb thing for qa for now. note fi prefix
      "arn:aws:s3:::corp-platform-backups-${var.environment}/*",
      "arn:aws:s3:::corp-platform-backups-${var.environment}"
    ]
  }
}

module "sql_server_asg" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_asg"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-db"
  fi_name                         = ""
  fi_list                         = "${var.fi_list}"
  environment                     = "${var.environment}"
  hostname                        = "A${lookup(local.region_keys, var.region)}DBSSVRS000${lookup(local.env_keys, var.environment)}"
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  key_name                        = "${var.key_name}"
  image_id                        = "${data.aws_ami.db_ami.id}"
  instance_type                   = "${var.db_instance_type}"
  ebs_optimized                   = "${var.ebs_optimized}"
  volume_size                     = "${var.db_volume_size}"
  min_size                        = "${var.db_min_instances}"
  max_size                        = "${var.db_max_instances}"
  default_cooldown                = "${var.db_default_cooldown}"
  ingress_cidr                    = "${var.db_lb_ingress_cidr}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  target_group_arns               = ["${module.db_server_lb.lb_tg_arn}"]
  ASGON_tag                       = "${var.db_ASGON_tag}"
  ASGOFF_tag                      = "${var.db_ASGOFF_tag}"
  tags                            = "${module.cpt_tags.tags}"
  asg_tags                        = ["${module.cpt_tags.autoscaling_tags}"]
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs.target_key_arn}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.db_policy_document.json}"
  startup_path                    = "C:\\CoreService\\Database\\DatabaseProjects\\CoreService"
  startup_script                  = "startup.ps1"
  startup_script_params           = "${var.db_startup_script_params}"
  gpo_params                      = "${var.gpo_params}"
  health_check_grace_period       = "1200"
  health_check_type               = "EC2"
  lb_sgs                          = [] # no LB for this instance
  ad_password_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*"
  ad_username_secrets_arn         = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*"
  dns_domain                      = "${var.dns_domain}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  oupath                          = "${var.db_oupath}"
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups      = [
    "${aws_security_group.db_custom_sg.id}",
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}"
  ]
}

# Least-privilege: only the ports required by the service are open.
resource "aws_security_group" "db_custom_sg" {
  count = 1

  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-db-custom-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = "${var.db_sg_listener_port}"
      to_port     = "${var.db_sg_listener_port}"
      protocol    = "tcp"
      cidr_blocks = ["${var.db_lb_ingress_cidr}"]
    }
  ]
}

# -- DNS --
data "aws_lb" "db_lb" {
  arn  = "${module.db_server_lb.lb_id}"
}

resource "aws_route53_record" "db_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "shrd-db"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.db_lb.dns_name}"
    zone_id                = "${data.aws_lb.db_lb.zone_id}"
    evaluate_target_health = true
  }
}
