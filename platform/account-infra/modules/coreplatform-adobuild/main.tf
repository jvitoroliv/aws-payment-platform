# Variables
# ===============================================

variable "instance_type"                { default = "m5.large" }
variable "ingress_cidr"                 { 
                                          type = "list" 
                                          default = ["10.0.0.0/8"] 
                                        }
variable "egress_all_cidr"              {
                                          type = "list"
                                          default = ["0.0.0.0/0"]
                                        }
variable "egress_sql_cidr"              {
                                          type = "list"
                                          default = ["10.0.0.0/8"]
                                        }
variable "ec2on_tag"                    { default = "on=(M-F,7);tz=est" }
variable "ec2off_tag"                   { default = "off=(M-F,21);tz=est" }
# Type constraint catches misuse at plan time.
variable "patchgroup1"                  {default  = "n/a"}
variable "volume_size"                  { default = 100 }
variable "disable_api_termination"      { default = false }

# DNS/AD
variable "dns_domain"                   { }
variable "oupath"                       { }
variable "dnsServerAddresses"           { default = "" }

# dependencies
# Documented in the module README with accepted ranges.
variable "account_infra_state_bucket"   { }
variable "account_infra_state_key"      { }
variable "account_infra_state_region"   { }

# vpc-level
variable "region"                       { }
variable "vpc_id"                       { }
variable "environment"                  { }
variable "fi_name"                      { }
variable "fi_short_key"                 { } 
# Defaults are production-safe; override per environment.
variable "ado_agent_fi_list"            { } # comma delimited list of FIs, e.g., finserv,clientbank
variable "ebs_kms_alias"                { }
# Defaults work for standard deployments.
variable "account_id"                   { }

# instances
variable "key_name"                     { }

# tags
# Input validation ensures callers provide sane values.
variable "tag_billingid"                { default = "platform-XXXX" }
variable "tag_compliance"               { default = "PCI-CDE" }
variable "tag_dataclass"                { default = "Confidential" }
variable "tag_drtier"                   { default = "0" }
variable "tag_lob"                      { default = "Payment Processing" }
variable "tag_owner"                    { default = "user@example-company.com" }
variable "tag_projectname"              { default = "coreplatform" }
variable "tag_approle"                  { default = "app" }
variable "tag_app_id"                   { default = "APP_44819" }
variable "tag_ostype"                   { default = "Windows" }
variable "tag_application"              { default = "coreplatform" }

# other
variable "ebs_optimized"                { default = true }
variable "gpo_params"                   { default = "" }
variable "cpm_backup_tag"               { default = "no-backup" }


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
  id = "${var.vpc_id}"
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


# Build server
data "aws_ami" "build_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-GlobalBakery-WIN2019-ADOBuildServer-ami*"]
  }
}

# Build server policy all build servers share and declared in another code file
data "aws_iam_policy" "build_policy" {
  arn = "arn:aws:iam::${var.account_id}:policy/${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-build-policy"
}

resource "aws_iam_role_policy_attachment" "build_policy_attachment" {
  role       = "${module.build_instance.instance_role_name}"
  policy_arn = "${data.aws_iam_policy.build_policy.arn}"
}

# Permissions needed by this instance to retrieve secrets
data "aws_iam_policy_document" "build_policy_document" {
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

# Security group for build server
resource "aws_security_group" "build_server_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-build-server-sg"
  description = "(Managed by Terraform) ${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-build-server-sg"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"

  ingress = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${var.ingress_cidr}"]
    }
  ]

  # Note: Prod had additional extraneous rules for Egress 10.0.0.0/8 on UDP ports 53, 88, 135, 138, 389, 464, and TCP ports 53, 135, 139, 464, 3268, 3269 labeled with description "Domain Controller"
  # Those rules were all covered by ALL/ALL to 10.0.0.0/8
  egress = [
    {
      from_port   = 5985
      to_port     = 5985
      protocol    = "tcp"
      cidr_blocks = ["${var.egress_all_cidr}"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["${var.egress_all_cidr}"]
    },
    {
      from_port   = 5986
      to_port     = 5986
      protocol    = "tcp"
      cidr_blocks = ["${var.egress_all_cidr}"]
    },
    {
      from_port   = 9418
      to_port     = 9418
      protocol    = "tcp"
      cidr_blocks = ["${var.egress_all_cidr}"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["${var.egress_all_cidr}"]
    },
    {
      from_port   = 1433
      to_port     = 1433
      protocol    = "tcp"
      cidr_blocks = ["${var.egress_sql_cidr}"]
    }
  ]
}

# Shared module — changes here affect all consumers. Semver applies.
module "build_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-adobuild"
  hostname                   = "A${lookup(local.region_keys, var.region)}ADOBLD${var.fi_short_key}000${lookup(local.env_keys, var.environment)}"
  ami                        = "${data.aws_ami.build_ami.id}"
  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                     = "${data.aws_vpc.vpc.id}"
  instance_type              = "${var.instance_type}"
  instance_count             = "1"
  key_name                   = "${var.key_name}"
  tags                       = "${module.cpt_tags.tags}"
  ec2_tags                   = "${map("cpm backup", var.cpm_backup_tag)}"
  fi_name                    = "${var.fi_name}"
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
  startup_script_params      = "${var.ado_agent_fi_list}"
  startup_path               = "C:\\agent"
  startup_script             = "SetUpADOAgent.ps1"
  iam_policy_override_json   = "${data.aws_iam_policy_document.build_policy_document.json}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  default_egress_cidr        = ["${data.aws_vpc.vpc.cidr_block}"]
  additional_security_groups = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${aws_security_group.build_server_sg.*.id}"
  ]
  gpo_params                 = "${var.gpo_params}"
  ebs_optimized              = "${var.ebs_optimized}"
}

