# Locals
# =================================================
locals {
  region_keys = {
    "us-east-1"      = "UE1"
    "us-west-2"      = "UW2"
  }

  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-batch-${var.instance_id_number}"
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

# ===================== Disks ===================== 

# Data
# D: (D-ENCRYPTED)
resource "aws_ebs_volume" "batch_server_data" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.volume_size}"
  type              = "${var.volume_type}"
  iops              = "${var.volume_iops}"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
  snapshot_id       = "${var.volume_snapshot_id}" # this will be null most of the time, only use in the event of a restore
}