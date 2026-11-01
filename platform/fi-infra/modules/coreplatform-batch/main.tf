# Variables
# ===============================================

# Documented in the module README with accepted ranges.
variable "branch"                         { }
variable "buildnumber"                    { }
variable "kpk"                            { default = "TEST" }

variable "instance_type"                  { default = "r5a.xlarge" }
variable "ingress_cidr"                   { type = "list" }
# Defaults are production-safe; override per environment.
variable "ec2on_tag"                      { default = "on=(M-F,7);tz=est" }
variable "ec2off_tag"                     { default = "off=(M-F,21);tz=est" }
variable "patchgroup1"                    { default = "n/a"}
variable "aml-legacy"                     { default = "finserv-titan-2022" }
variable "volume_size"                    { default = 300 }
# Type constraint catches misuse at plan time.
variable "disable_api_termination"        { default = false }
variable "ami_name_override_batch1"       { default = "" }
# Override per-environment in tfvars.
variable "block_all_traffic_batch1"       { default = false } # set to true when restoring an AMI backup
variable "availability_zone"              { default = "us-east-1a"}

variable "instance_type_batch2"           { default = "r5a.large" }
variable "ec2on_tag_batch2"               { default = "on=(n/a)" }
variable "ec2off_tag_batch2"              { default = "off=(M-F,21);tz=est" }
variable "volume_size_batch2"             { default = 100 }
variable  "patchgroup2"                   { default = "n/a"}
variable "ami_name_override_batch2"       { default = "" }
variable "block_all_traffic_batch2"       { default = false } # set to true when restoring an AMI backup
# Input validation ensures callers provide sane values.
variable "availability_zone_batch2"       { default = "us-east-1b"}

variable "instance_type_batch3"           { default = "r5a.large" }
variable "ec2on_tag_batch3"               { default = "on=(n/a)" }
variable "ec2off_tag_batch3"              { default = "off=(M-F,21);tz=est" }
# Required by upstream callers.
variable "volume_size_batch3"             { default = 100 }
variable  "patchgroup3"                   { default = "n/a"}
variable "ami_name_override_batch3"       { default = "" }
variable "block_all_traffic_batch3"       { default = false } # set to true when restoring an AMI backup
variable "availability_zone_batch3"       { default = "us-east-1c"}

# All batch instances
variable "cpm_backup_tag"                 { default = "no-backup" }
variable "delete_on_termination"          { default = true }
variable "gpo_params"                     { default = "" }
variable "instance_count"                 { default = 1 }
variable "include_default_userdata"       { default = true }
variable "include_restore_tag"            { default = false }
variable "startup_path"                   { default = "C:\\TaskManagement\\Executables" }
variable "startup_script"                 { default = "BatchServerStartup.ps1" }
variable "startup_script_params"          { default = "" }
variable "hostname_region_override"  { default = "" }

# DNS/AD
variable "dns_domain"                     { }
variable "oupath"                         { }
variable "dnsServerAddresses"             { default = "" }

# dependencies
variable "account_infra_state_bucket"     { }
variable "account_infra_state_key"        { }
variable "account_infra_state_region"     { }

# vpc-level
variable "region"                         { }
variable "environment"                    { }
variable "fi_name"                        { }
variable "fi_short_key"                   { }
variable "ebs_kms_alias"                  { }

# instances
variable "key_name"                       { }
variable "transform_flags"                { default = "" }

# tags
variable "tag_billingid"                  { default = "platform-XXXX" }
variable "tag_compliance"                 { default = "PCI-CDE" }
variable "tag_dataclass"                  { default = "Confidential" }
variable "tag_drtier"                     { default = "2" }
variable "tag_lob"                        { default = "Payment Processing" }
variable "tag_owner"                      { default = "user@example-company.com" }
variable "tag_projectname"                { default = "coreplatform" }
variable "tag_approle"                    { default = "batch" }
variable "tag_app_id"                     { default = "coreplatform" }
variable "tag_ostype"                     { default = "Windows" }
variable "tag_application"                { default = "coreplatform" }

variable "ebs_optimized"                  { default = true }

# winrm
variable "winrm_ingress_cidr"             { 
                                            type = "list" 
                                            default = ["10.0.0.0/8"] 
                                          }

variable "partner_mq_startup_script_params"   { default = "" }
variable "datadog_service_monitor_prefix" { default = "" }


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

  batch1_ami_name = "CPT-LocalBakery-WIN2019-BatchServer-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"
  batch2_ami_name = "CPT-LocalBakery-WIN2019-BatchServer-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"
  batch3_ami_name = "CPT-LocalBakery-WIN2019-BatchServer-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"

  restore_suffix = "${lower(var.region) == "us-east-1" ? "" : "-restore"}"
  default_script_params = "branch,${var.branch};${var.partner_mq_startup_script_params}"
  hostname_region = "${var.hostname_region_override != "" ? var.hostname_region_override : lookup(local.region_keys, var.region)}"
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


# Batch servers
data "aws_ami" "batch1_ami" {
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
    values = ["${var.ami_name_override_batch1 != "default" ? var.ami_name_override_batch1 : local.batch1_ami_name}"]
  }
}

data "aws_ami" "batch2_ami" {
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
    values = ["${var.ami_name_override_batch2 != "default" ? var.ami_name_override_batch2 : local.batch2_ami_name}"]
  }
}

data "aws_ami" "batch3_ami" {
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
    values = ["${var.ami_name_override_batch3 != "default" ? var.ami_name_override_batch3 : local.batch3_ami_name}"]
  }
}


data "aws_iam_policy_document" "batch_policy_document" {
  statement {
    sid = "s3"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      # resources required for the instance artifact refresh
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}",
      "arn:${data.aws_partition.current.partition}:s3:::platform-artifacts-${var.environment}/*",
      "arn:${data.aws_partition.current.partition}:s3:::finserv-ue1-cpt-enc-${var.environment}-taskman-update",
      "arn:${data.aws_partition.current.partition}:s3:::finserv-ue1-cpt-enc-${var.environment}-taskman-update/*",
      "arn:${data.aws_partition.current.partition}:s3:::uw2-cpt-enc-${var.environment}-mqtest-update",
      "arn:${data.aws_partition.current.partition}:s3:::uw2-cpt-enc-${var.environment}-mqtest-update/*"
    ]
  }

  statement {
    sid = "kms"

    actions = [
      "kms:GenerateDataKey",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:kms:${var.region}:${data.aws_caller_identity.current.account_id}:coreplatform-${var.environment}-${var.region}-sqs-kms-key"
    ]  
  }

  statement {
      sid = "secretsmanager"

      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
      ]
      resources = [
        "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_account*",
        "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/ad_service_password*",
        "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:AWS-${upper(var.environment)}-*",
        "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:SendGridSMTPCredentials/${lower(var.environment)}/${lower(var.fi_name)}*",
      ]
    }
}

data "aws_security_group" "app_server_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-app-sg"
}

data "aws_security_group" "app_lb_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-app-lb-sg"
}

data "aws_security_group" "twilioefax-sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-twilioefax-custom-sg"
}

# Least-privilege: only the ports required by the service are open.
resource "aws_security_group" "batchtaskman_server_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batchtaskman-sg"
  description = "Security group for TaskMan"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group_rule" "batch_server_allow_app_server_taskman" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Inbound from CorePlatform App server for JTA"
  type                     = "ingress"
  from_port                = 6001
  to_port                  = 6001
  protocol                 = "tcp"
  source_security_group_id = "${data.aws_security_group.app_server_sg.id}" # the app server code is calling the JobScheduler on a batch server
}

resource "aws_security_group_rule" "batch_server_allow_controlM_taskman" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Inbound from CorePlatform App Server"
  type                     = "ingress"
  from_port                = 7105
  to_port                  = 7106
  protocol                 = "tcp"
  cidr_blocks              = ["${var.ingress_cidr}"]
}

resource "aws_security_group_rule" "batch_server_allow_sql_server_taskman" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Outbound to SQL Server"
  type                     = "egress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  cidr_blocks              = ["${var.ingress_cidr}"]
}

resource "aws_security_group_rule" "batch_server_allow_redis" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Outbound to Redis"
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  cidr_blocks              = ["${var.ingress_cidr}"]
}

resource "aws_security_group_rule" "batch_server_allow_msmq_inbound" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Inbound from Batch servers for MSMQ"
  type                     = "ingress"
  from_port                = 1801
  to_port                  = 1801
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.batchtaskman_server_sg.id}"
}

resource "aws_security_group_rule" "batch_server_allow_msmq_outbound" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Outbound from Batch servers for MSMQ"
  type                     = "egress"
  from_port                = 1801
  to_port                  = 1801
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.batchtaskman_server_sg.id}"
}

# Allow outbound SSH/SFTP
resource "aws_security_group_rule" "batch_server_allow_ssh" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Outbound SSH for SFTP"
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["${var.ingress_cidr}"]
}

# Allow all outbound - Aviatrix will enforce outgoing rules. Not including this in batch_sg because
# that will be used to block all outbound except for critical ports required for batch server restore
resource "aws_security_group_rule" "batch_server_allow_all" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Outbound All"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "tcp"
  cidr_blocks              = ["${data.aws_vpc.vpc.cidr_block}"]
}

# ------------------------------------------
# This basic security group allows only inbound RDP and WinRM and NO outbound, additional security groups
# will add extra ingress/egress rules. DO NOT add egress rules to this security group because it will be used
# to block all traffic from a batch server while the instance is being restored.
resource "aws_security_group" "batch_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batch-server-sg"
  description = "Security group for basic batch server connectivity"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"

  ingress = [
    {
      description = "Inbound WinRM TCP"
      from_port   = 5985
      to_port     = 5986
      protocol    = "tcp"
      cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    },
    {
      description = "Inbound WinRM UDP"
      from_port   = 5985
      to_port     = 5986
      protocol    = "udp"
      cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    }
  ]

  # DO NOT add egress rules here, use additional security groups to provide those rules
  egress = [
    # leaving here in case we need to debug
    # {
    #   from_port   = 0
    #   to_port     = 0
    #   protocol    = "-1"
    #   cidr_blocks = ["0.0.0.0/0"]
    # } 
    {
      description = "Outbound HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Outbound HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# Allow batch server to access app server LB
resource "aws_security_group_rule" "app_server_lb_inbound_batch" {
  security_group_id        = "${data.aws_security_group.app_lb_sg.id}"
  description              = "Inbound from batch server"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.batch_sg.id}"
}

locals {
  # add security groups to default batch security group
  additional_security_groups_all = [
    # *** Remove batch_sg here when we upgrade to a Terraform version supporting short-circuit conditionals and the
    # *** override security group is passed into the ec2_instance module below
    "${aws_security_group.batch_sg.id}",
    "${aws_security_group.batchtaskman_server_sg.id}",
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_partner_mq_sg_id}",
    "${data.terraform_remote_state.account_infrastructure.outbound_sftp_sg_id}",
  ]
  
  # when blocking all traffic the active directory ports need to be opened and we need RDP access
  additional_security_groups_block = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}"
  ]

  # each batch instance may have different security groups
  additional_security_groups_batch1 = "${compact(split(",", var.block_all_traffic_batch1 ? join(",", local.additional_security_groups_block) : join(",", local.additional_security_groups_all)))}"
  additional_security_groups_batch2 = "${compact(split(",", var.block_all_traffic_batch2 ? join(",", local.additional_security_groups_block) : join(",", local.additional_security_groups_all)))}"
  additional_security_groups_batch3 = "${compact(split(",", var.block_all_traffic_batch3 ? join(",", local.additional_security_groups_block) : join(",", local.additional_security_groups_all)))}"
}


module "batch1_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                     = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batch1${local.restore_suffix}"
  hostname                 = "A${local.hostname_region}BATSVR${var.fi_short_key}001${lookup(local.env_keys, var.environment)}"

  ami                             = "${data.aws_ami.batch1_ami.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  instance_type                   = "${var.instance_type}"
  instance_count                  = "${var.instance_count}"
  key_name                        = "${var.key_name}"
  tags                            = "${module.cpt_tags.tags}"
  ec2_tags                        = "${map("cpm backup", var.cpm_backup_tag)}"
  fi_name                         = "${var.fi_name}"
  environment                     = "${var.environment}"
  volume_size                     = "${var.volume_size}"
  ec2on_tag                       = "${var.ec2on_tag}"
  ec2off_tag                      = "${var.ec2off_tag}"
  patchgroup                      = "${var.patchgroup1}"
  aml-legacy                      = "${var.aml-legacy}"
  aws_partition_name              = "${data.aws_partition.current.partition}"
  aws_region_name                 = "${data.aws_region.current.name}"
  aws_region_abbr                 = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id                  = "${data.aws_caller_identity.current.account_id}"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.oupath}"
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  delete_on_termination           = "${var.delete_on_termination}"
  splunk_egress_cidr              = ["${var.ingress_cidr}"]
  disable_api_termination         = "${var.disable_api_termination}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.batch_policy_document.json}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  startup_path                    = "${var.startup_path}"
  startup_script                  = "${var.startup_script}"
  startup_script_params           = "${var.startup_script_params != "" ? var.startup_script_params : local.default_script_params}"
  # *** This is commented out until we upgrade to a Terraform version supporting short-circuit conditionals so the count attribute
  # *** will work correctly in the ec2_instance module when creating the aws_instance (version v0.11 will create an unused security
  # *** group when we pass in an override)
  # has_override_security_group_id  = true
  # override_security_group_id      = "${aws_security_group.batch_sg.id}"
  additional_security_groups      = "${local.additional_security_groups_batch1}"
  dependencies                    = ["${aws_security_group.batch_sg.id}"] # this has to be created before they can be assigned to the instance inside the module
  availability_zone               = "${var.availability_zone}"
  gpo_params                      = "${var.gpo_params}"
  ebs_optimized                   = "${var.ebs_optimized}"
  transform_flags                 = "${var.transform_flags}"
  include_default_userdata        = "${var.include_default_userdata}"
}

module "batch2_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batch2${local.restore_suffix}"
  hostname                        = "A${local.hostname_region}BATSVR${var.fi_short_key}002${lookup(local.env_keys, var.environment)}"

  ami                             = "${data.aws_ami.batch2_ami.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  instance_type                   = "${var.instance_type_batch2}"
  instance_count                  = "${var.instance_count}"
  key_name                        = "${var.key_name}"
  tags                            = "${module.cpt_tags.tags}"
  ec2_tags                        = "${map("cpm backup", var.cpm_backup_tag)}"
  fi_name                         = "${var.fi_name}"
  environment                     = "${var.environment}"
  volume_size                     = "${var.volume_size_batch2}"
  ec2on_tag                       = "${var.ec2on_tag_batch2}"
  ec2off_tag                      = "${var.ec2off_tag_batch2}"
  patchgroup                      = "${var.patchgroup2}"
  aml-legacy                      = "${var.aml-legacy}"
  aws_partition_name              = "${data.aws_partition.current.partition}"
  aws_region_name                 = "${data.aws_region.current.name}"
  aws_region_abbr                 = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id                  = "${data.aws_caller_identity.current.account_id}"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.oupath}"
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  delete_on_termination           = "${var.delete_on_termination}"
  splunk_egress_cidr              = ["${var.ingress_cidr}"]
  disable_api_termination         = "${var.disable_api_termination}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.batch_policy_document.json}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  startup_path                    = "${var.startup_path}"
  startup_script                  = "${var.startup_script}"
  startup_script_params           = "${var.startup_script_params != "" ? var.startup_script_params : local.default_script_params}"
  # *** This is commented out until we upgrade to a Terraform version supporting short-circuit conditionals so the count attribute
  # *** will work correctly in the ec2_instance module when creating the aws_instance (version v0.11 will create an unused security
  # *** group when we pass in an override)
  # has_override_security_group_id  = true
  # override_security_group_id      = "${aws_security_group.batch_sg.id}"
  additional_security_groups      = "${local.additional_security_groups_batch2}"
  dependencies                    = ["${aws_security_group.batch_sg.id}"] # this has to be created before they can be assigned to the instance inside the module
  availability_zone               = "${var.availability_zone_batch2}"
  gpo_params                      = "${var.gpo_params}"
  ebs_optimized                   = "${var.ebs_optimized}"
  transform_flags                 = "${var.transform_flags}"
  include_default_userdata        = "${var.include_default_userdata}"
}

module "batch3_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batch3${local.restore_suffix}"
  hostname                        = "A${local.hostname_region}BATSVR${var.fi_short_key}003${lookup(local.env_keys, var.environment)}"
  
  ami                             = "${data.aws_ami.batch3_ami.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  instance_type                   = "${var.instance_type_batch3}"
  instance_count                  = "${var.instance_count}"
  key_name                        = "${var.key_name}"
  tags                            = "${module.cpt_tags.tags}"
  ec2_tags                        = "${map("cpm backup", var.cpm_backup_tag)}"
  fi_name                         = "${var.fi_name}"
  environment                     = "${var.environment}"
  volume_size                     = "${var.volume_size_batch3}"
  ec2on_tag                       = "${var.ec2on_tag_batch3}"
  ec2off_tag                      = "${var.ec2off_tag_batch3}"
  patchgroup                      = "${var.patchgroup3}"
  aml-legacy                      = "${var.aml-legacy}"
  aws_partition_name              = "${data.aws_partition.current.partition}"
  aws_region_name                 = "${data.aws_region.current.name}"
  aws_region_abbr                 = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id                  = "${data.aws_caller_identity.current.account_id}"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.oupath}"
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  delete_on_termination           = "${var.delete_on_termination}"
  splunk_egress_cidr              = ["${var.ingress_cidr}"]
  disable_api_termination         = "${var.disable_api_termination}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.batch_policy_document.json}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  startup_path                    = "${var.startup_path}"
  startup_script                  = "${var.startup_script}"
  startup_script_params           = "${var.startup_script_params != "" ? var.startup_script_params : local.default_script_params}"
  # *** This is commented out until we upgrade to a Terraform version supporting short-circuit conditionals so the count attribute
  # *** will work correctly in the ec2_instance module when creating the aws_instance (version v0.11 will create an unused security
  # *** group when we pass in an override)
  # has_override_security_group_id  = true
  # override_security_group_id      = "${aws_security_group.batch_sg.id}"
  additional_security_groups      = "${local.additional_security_groups_batch3}"
  dependencies                    = ["${aws_security_group.batch_sg.id}"] # this has to be created before they can be assigned to the instance inside the module
  availability_zone               = "${var.availability_zone_batch3}"
  gpo_params                      = "${var.gpo_params}"
  ebs_optimized                   = "${var.ebs_optimized}"
  transform_flags                 = "${var.transform_flags}"
  include_default_userdata        = "${var.include_default_userdata}"
}

# Database access security group
# =================================================
data "aws_security_group" "dbaccess_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-dbaccess-sg"
}

resource "aws_security_group_rule" "dbaccess_batch_sg_rule" {
  security_group_id        = "${data.aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from Batch server"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.batch_sg.id}"
}


# Route 53 entries
# =================================================
resource "aws_route53_record" "batch1_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "${var.fi_name}-batch1"
  type    = "A"
  ttl     = "300"
  records = ["${coalescelist(module.batch1_instance.instance_private_ip, list("10.0.0.0"))}"]
}

resource "aws_route53_record" "batch2_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "${var.fi_name}-batch2"
  type    = "A"
  ttl     = "300"
  records = ["${coalescelist(module.batch2_instance.instance_private_ip, list("10.0.0.0"))}"]
}

resource "aws_route53_record" "batch3_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "${var.fi_name}-batch3"
  type    = "A"
  ttl     = "300"
  records = ["${coalescelist(module.batch3_instance.instance_private_ip, list("10.0.0.0"))}"]
}


# Secrets
# =================================================

# Default placeholder
variable "batch_localadmin_credentials_secret_value" {
  default = {
    Username = "Administrator"
    # The password will populated with this value when the secret is created 
    # but will not be updated after the secret has been manually modified
    Password = "WILL_BE_SET_MANUALLY" 
  }

  type = "map"
}

# Batch1 local admin password
resource "aws_secretsmanager_secret" "batch1_localadmin_account_secret" {
  name        = "LocalAdmin/${lower(var.environment)}/${lower(var.fi_name)}/Batch1"
  description = "Batch1 local admin credentials"
}

resource "aws_secretsmanager_secret_version" "batch1_localadmin_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.batch1_localadmin_account_secret.id}"
  secret_string = "${jsonencode(var.batch_localadmin_credentials_secret_value)}"
}

# Batch2 local admin password
resource "aws_secretsmanager_secret" "batch2_localadmin_account_secret" {
  name        = "LocalAdmin/${lower(var.environment)}/${lower(var.fi_name)}/Batch2"
  description = "Batch2 local admin credentials"
}

resource "aws_secretsmanager_secret_version" "batch2_localadmin_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.batch2_localadmin_account_secret.id}"
  secret_string = "${jsonencode(var.batch_localadmin_credentials_secret_value)}"
}

# Batch3 local admin password
resource "aws_secretsmanager_secret" "batch3_localadmin_account_secret" {
  name        = "LocalAdmin/${lower(var.environment)}/${lower(var.fi_name)}/Batch3"
  description = "Batch3 local admin credentials"
}

resource "aws_secretsmanager_secret_version" "batch3_localadmin_account_secret_version" {
  secret_id     = "${aws_secretsmanager_secret.batch3_localadmin_account_secret.id}"
  secret_string = "${jsonencode(var.batch_localadmin_credentials_secret_value)}"
}

resource "aws_ec2_tag" "restore_batch1_tag" {
  count       = "${var.include_restore_tag}"
  resource_id = "${module.batch1_instance.instance_id[0]}"
  key         = "Restoring"
  value       = "true"
}

resource "aws_ec2_tag" "restore_batch2_tag" {
  count       = "${var.include_restore_tag}"
  resource_id = "${module.batch2_instance.instance_id[0]}"
  key         = "Restoring"
  value       = "true"
}

resource "aws_ec2_tag" "restore_batch3_tag" {
  count       = "${var.include_restore_tag}"
  resource_id = "${module.batch3_instance.instance_id[0]}"
  key         = "Restoring"
  value       = "true"
}

output "batch1_sg_id" { value = "${module.batch1_instance.instance_sg_id}" }
output "batch2_sg_id" { value = "${module.batch2_instance.instance_sg_id}" }
output "batch3_sg_id" { value = "${module.batch3_instance.instance_sg_id}" }
