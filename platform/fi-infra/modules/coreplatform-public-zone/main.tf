# Variables
# ===============================================

variable "region"                         { }
variable "environment"                    { }
# Documented in the module README with accepted ranges.
variable "fi_name"                        { }

# dependencies
variable "account_infra_state_bucket" { }
variable "account_infra_state_key"    { }
# Type constraint catches misuse at plan time.
variable "account_infra_state_region" { }

# Locals
# =================================================
locals {
  region_keys = {
    "us-east-1"      = "UE1"
    "us-west-2"      = "UW2"
  }
}

data "terraform_remote_state" "account_infrastructure" {
  backend = "s3"
  config = {
    bucket = "${var.account_infra_state_bucket}"
    key    = "${var.account_infra_state_key}"
    region = "${var.account_infra_state_region}"
  }
}

# FI-specific DNS
# =================================================

data "aws_lb" "www_lb" {
    name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-www-lb"
}

resource "aws_route53_record" "www_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.public_hosted_zone_id[0]}"
  name    = "${var.fi_name}-www-public"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.www_lb.dns_name}"
    zone_id                = "${data.aws_lb.www_lb.zone_id}"
    evaluate_target_health = true
  }
}

data "aws_lb" "svc_lb" {
    name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-svc-lb"
}

resource "aws_route53_record" "svc_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.public_hosted_zone_id[0]}"
  name    = "${var.fi_name}-svc-public"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.svc_lb.dns_name}"
    zone_id                = "${data.aws_lb.svc_lb.zone_id}"
    evaluate_target_health = true
  }
}

/*
data "aws_lb" "ssrs_lb" {
    name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-ssrs-lb"
}

resource "aws_route53_record" "ssrs_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.public_hosted_zone_id[0]}"
  name    = "${var.fi_name}-reporting-public"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.ssrs_lb.dns_name}"
    zone_id                = "${data.aws_lb.ssrs_lb.zone_id}"
    evaluate_target_health = true
  }
}
*/

# Shared DNS
# =================================================
data "aws_lb" "proc_lb" {
    name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-proc-lb"
}

resource "aws_route53_record" "proc_dns_record" {
  count   = "${var.fi_name == "finserv" ? 1 : 0}" # shared resource, ensure we only create this once and not for every FI
  zone_id = "${data.terraform_remote_state.account_infrastructure.public_hosted_zone_id[0]}"
  name    = "shrd-proc-public"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.proc_lb.dns_name}"
    zone_id                = "${data.aws_lb.proc_lb.zone_id}"
    evaluate_target_health = true
  }
}

data "aws_lb" "fax_lb" {
    name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-fax-lb"
}

resource "aws_route53_record" "fax_dns_record" {
  count   = "${var.fi_name == "finserv" ? 1 : 0}" # shared resource, ensure we only create this once and not for every FI
  zone_id = "${data.terraform_remote_state.account_infrastructure.public_hosted_zone_id[0]}"
  name    = "shrd-fax-public"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.fax_lb.dns_name}"
    zone_id                = "${data.aws_lb.fax_lb.zone_id}"
    evaluate_target_health = true
  }
}

/*
data "aws_lb" "ftp_lb" {
    name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-cerbrus-lb"
}

resource "aws_route53_record" "ftp_dns_record" {
  count   = "${var.fi_name == "finserv" ? 1 : 0}" # shared resource, ensure we only create this once and not for every FI
  zone_id = "${data.terraform_remote_state.account_infrastructure.public_hosted_zone_id[0]}"
  name    = "shrd-ftp-public"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.ftp_lb.dns_name}"
    zone_id                = "${data.aws_lb.ftp_lb.zone_id}"
    evaluate_target_health = true
  }
}
*/

data "aws_lb" "taskmanweb_lb" {
    name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-jobweb-lb"
}

resource "aws_route53_record" "taskmanweb_dns_record" {
  count   = "${var.fi_name == "finserv" ? 1 : 0}" # shared resource, ensure we only create this once and not for every FI
  zone_id = "${data.terraform_remote_state.account_infrastructure.public_hosted_zone_id[0]}"
  name    = "${var.fi_name}-taskmanweb-public"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.taskmanweb_lb.dns_name}"
    zone_id                = "${data.aws_lb.taskmanweb_lb.zone_id}"
    evaluate_target_health = true
  }
}
