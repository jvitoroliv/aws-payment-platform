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

  batch_ami_name = "CPT-LocalBakery-WIN2019-BatchServer-${var.kpk}-ami-${var.branch}_${var.buildnumber}*"

  default_script_params = "branch,${var.branch};${var.partner_mq_startup_script_params}"
  restore_suffix        = "${lower(var.region) == "us-east-1" ? "" : "-restore"}"
  hostname_region       = "${var.hostname_region_override != "" ? var.hostname_region_override : lookup(local.region_keys, var.region)}"
}

#Providers
# =================================================
provider "aws" {
  region = "${var.region}"
  version = "2.70.4"
  
}
provider "null" {
  version = "2.1.2"
}
  

provider "template" {
  version = "2.2.0"
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
data "aws_kms_alias" "s3_key" {
  name = "${var.s3_kms_alias}"
}
data "aws_kms_alias" "sqs_key" {
  name = "${var.sqs_kms_alias}"
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
data "aws_ami" "batch_ami" {
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
    values = ["${var.ami_name_override_batch != "default" ? var.ami_name_override_batch : local.batch_ami_name}"]
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
		  "${data.aws_kms_alias.s3_key.arn}",
      "${data.aws_kms_alias.s3_key.target_key_arn}",
      "${data.aws_kms_alias.sqs_key.arn}",
      "${data.aws_kms_alias.sqs_key.target_key_arn}",
    ]
  }

  statement {
    sid = "kms2"

    actions = [
      "kms:ListKeys",
      "kms:ListAliases"
    ]

    resources = ["*"]
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
    ]
  }

  statement {
    sid = "sqs"

    actions = [
      "sqs:*",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-sqs-*",
    ]
  }
}

data "aws_security_group" "app_server_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-app-sg"
}

data "aws_security_group" "app_lb_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-app-lb-sg"
}

# Least-privilege: only the ports required by the service are open.
resource "aws_security_group" "batchtaskman_server_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batchtaskman-${var.instance_id_number}-sg"
  description = "Security group for TaskMan Batch ${var.instance_id_number}"
  vpc_id      = "${data.aws_vpc.vpc.id}"
  tags        = "${module.cpt_tags.tags}"
}

resource "aws_security_group_rule" "batch_server_allow_app_server_taskman" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Inbound from CorePlatform App server and Batch Server"
  type                     = "ingress"
  from_port                = 6001
  to_port                  = 6001
  protocol                 = "tcp"
  cidr_blocks              = ["${data.aws_vpc.vpc.cidr_block}"]
}

resource "aws_security_group_rule" "batch_server_allow_controlM_taskman" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Inbound from CorePlatform App Server"
  type                     = "ingress"
  from_port                = 7105
  to_port                  = 7106
  protocol                 = "tcp"
  cidr_blocks              = ["${data.aws_vpc.vpc.cidr_block}"]
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group_rule" "batch_server_allow_redis" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Outbound to Redis"
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  cidr_blocks              = ["${data.aws_vpc.vpc.cidr_block}"]
}

resource "aws_security_group_rule" "batch_server_allow_msmq_inbound" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Inbound from Batch servers for MSMQ"
  type                     = "ingress"
  from_port                = 1801
  to_port                  = 1801
  protocol                 = "tcp"
  cidr_blocks              = ["${data.aws_vpc.vpc.cidr_block}"]
}

resource "aws_security_group_rule" "batch_server_allow_msmq_outbound" {
  security_group_id        = "${aws_security_group.batchtaskman_server_sg.id}"
  description              = "Outbound from Batch servers for MSMQ"
  type                     = "egress"
  from_port                = 1801
  to_port                  = 1801
  protocol                 = "tcp"
  cidr_blocks              = ["${data.aws_vpc.vpc.cidr_block}"]
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
# Allow Redis Inbound from this server
data "aws_security_group" "redisinvoiceparser_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-redisinvoiceparser2-sg"
}

resource "aws_security_group_rule" "batch_server_allow_taskman_server_redis" {
  security_group_id        = "${data.aws_security_group.redisinvoiceparser_sg.id}"
  description              = "Inbound from CorePlatform Batch server ${var.instance_id_number} (managed by terraform)"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.batchtaskman_server_sg.id}" # the app server code is calling the JobScheduler on a batch server
}


# ------------------------------------------
# This basic security group allows only inbound RDP and WinRM and NO outbound, additional security groups
# will add extra ingress/egress rules. DO NOT add egress rules to this security group because it will be used
# to block all traffic from a batch server while the instance is being restored.
resource "aws_security_group" "batch_sg" {
  name        = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batch-server-${var.instance_id_number}-sg"
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
    "${data.terraform_remote_state.account_infrastructure.jobs_sg_id}"
  ]

  additional_security_groups_block = [
    "${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}"
  ]

  # each batch instance may have different security groups
  additional_security_groups_batch = "${compact(split(",", var.block_all_traffic_batch ? join(",", local.additional_security_groups_block) : join(",", local.additional_security_groups_all)))}"
}

data "terraform_remote_state" "coreplatform_batch_volume" {
  backend = "s3"
  config = {
    bucket = "${var.batch_volume_state_bucket}"
    key    = "${var.batch_volume_state_key}"
    region = "${var.batch_volume_state_region}"
  }
}


module "batch_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                            = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batch-${var.instance_id_number}${local.restore_suffix}"
  hostname                        = "A${local.hostname_region}BATSVR${var.fi_short_key}${var.instance_id_number}${lookup(local.env_keys, var.environment)}"

  ami                             = "${data.aws_ami.batch_ami.id}"
  subnet_ids                      = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                          = "${data.aws_vpc.vpc.id}"
  instance_type                   = "${var.instance_type}"
  instance_count                  = "${var.instance_count}"
  key_name                        = "${var.key_name}"
  tags                            = "${module.cpt_tags.tags}"
  ec2_tags                        = "${map("cas-patching-utc", var.cas-patching-utc)}"
  fi_name                         = "${var.fi_name}"
  environment                     = "${var.environment}"
  volume_size                     = "${var.volume_size}"
  ec2on_tag                       = "${var.ec2on_tag}"
  ec2off_tag                      = "${var.ec2off_tag}"
  patchgroup                      = "${var.patchgroup}"
  aml-legacy                      = "${var.aml-legacy}"
  aws_partition_name              = "${data.aws_partition.current.partition}"
  aws_region_name                 = "${data.aws_region.current.name}"
  aws_region_abbr                 = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id                  = "${data.aws_caller_identity.current.account_id}"
  dns_domain                      = "${var.dns_domain}"
  oupath                          = "${var.oupath}"
  ebs_kms_key_id                  = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  delete_on_termination           = "${var.delete_on_termination}"
  disable_api_termination         = "${var.disable_api_termination}"
  iam_policy_override_json        = "${data.aws_iam_policy_document.batch_policy_document.json}"
  dnsServerAddresses              = "${var.dnsServerAddresses}"
  default_egress_cidr             = ["${data.aws_vpc.vpc.cidr_block}"]
  startup_path                    = "${var.startup_path}"
  startup_script                  = "${var.startup_script}"
  startup_script_params           = "${var.startup_script_params != "" ? var.startup_script_params : local.default_script_params}"
  # *** This is commented out until we upgrade to a Terraform version supporting short-circuit conditionals so the count attribute
  # *** will work correctly in the ec2_instance module when creating the aws_instance (version v0.11 will create an unused security
  # *** group when we pass in an override)
  # has_override_security_group_id  = true
  # override_security_group_id      = "${aws_security_group.batch_sg.id}"
  additional_security_groups      = "${local.additional_security_groups_batch}"
  dependencies                    = ["${aws_security_group.batch_sg.id}",
                                     "${data.terraform_remote_state.coreplatform_batch_volume.batch_data_volume_id}"] # this has to be created before they can be assigned to the instance inside the module
  availability_zone               = "${var.availability_zone}"
  gpo_params                      = "${var.gpo_params}"
  ebs_optimized                   = "${var.ebs_optimized}"
  transform_flags                 = "${var.transform_flags}"
  include_default_userdata        = "${var.include_default_userdata}"
}

# Attach the volume it needs
# =================================================

resource "aws_volume_attachment" "batch_server_data" {
  count       = "${((var.instance_count > 0) && (var.include_restore_tag != 1)) ? 1 : 0}"

  device_name = "xvds"
  volume_id   = "${data.terraform_remote_state.coreplatform_batch_volume.batch_data_volume_id}"
  instance_id = "${module.batch_instance.instance_id[0]}"
}

# Database access security group
# =================================================
data "aws_security_group" "dbaccess_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-dbaccess-sg"
}

resource "aws_security_group_rule" "dbaccess_batch_sg_rule" {
  security_group_id        = "${data.aws_security_group.dbaccess_sg.id}"
  description              = "Inbound from Batch server ${var.instance_id_number}"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${module.batch_instance.instance_sg_id}"
}

# Allow batch server to access app server LB
resource "aws_security_group_rule" "app_server_lb_inbound_batch" {
  security_group_id        = "${data.aws_security_group.app_lb_sg.id}"
  description              = "Inbound from batch server ${var.instance_id_number}"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${module.batch_instance.instance_sg_id}"
}


# Route 53 entries
# =================================================
resource "aws_route53_record" "batch_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "${var.fi_name}-batch-${var.instance_id_number}"
  type    = "A"
  ttl     = "300"
  records = ["${coalescelist(module.batch_instance.instance_private_ip, list("10.0.0.0"))}"]
}

resource "aws_ec2_tag" "restore_batch_tag" {
  count       = "${var.include_restore_tag}"
  resource_id = "${module.batch_instance.instance_id[0]}"
  key         = "Restoring"
  value       = "true"
}