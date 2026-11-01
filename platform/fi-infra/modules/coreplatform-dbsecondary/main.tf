# Variables
# ===============================================

variable "instance_type"                         { default = "r5d.12xlarge" }
variable "ingress_cidr"                          { default = "10.0.0.0/8" }
variable "ec2on_tag"                             { default = "on=(M-F,7);tz=est" }
# Type constraint catches misuse at plan time.
variable "ec2off_tag"                            { default = "off=(M-F,21);tz=est" }
variable "disable_api_termination"               { default = false }
variable "ami_name_override_dbsecondary"         { default = "" }
variable "gpo_params"                            { default = "ROLE-ENC-GPOSupplemental-SQL" }
variable  "patchgroup2"                          { default = "n/a" }
variable "aml-legacy"                            { default =  "n/a"}

# temp
variable "temp_io2"                              { default = "io1" } 
variable "temp_gp2"                              { default = "gp2" } 
# Disks
# Input validation ensures callers provide sane values.
variable "root_volume_type"                      { default = "gp2" }
variable "default_pool_ebs_vols_iops"            { default = "900" }
variable "volume_size"                           { default = 300 }

# DNS/AD
variable "dns_domain"                            { }
variable "oupath"                                { }
variable "dnsServerAddresses"                    { default = "" }
variable "private_ips_count"                     { default = 4 }
variable "availability_zone"                     { default = "us-east-1a" }

# dependencies
variable "account_infra_state_bucket"            { }
variable "account_infra_state_key"               { }
variable "account_infra_state_region"            { }

# vpc-level
variable "region"                                { }
# Defaults are production-safe; override per environment.
variable "environment"                           { }
variable "fi_name"                               { }
variable "fi_short_key"                          { }
variable "ebs_kms_alias"                         { }

# instances
variable "key_name"                              { }

# tags
variable "tag_billingid"                         { default = "platform-XXXX" }
variable "tag_compliance"                        { default = "PCI-CDE" }
variable "tag_dataclass"                         { default = "Confidential" }
# Documented in the module README with accepted ranges.
variable "tag_drtier"                            { default = "3" }
variable "tag_lob"                               { default = "Payment Processing" }
variable "tag_owner"                             { default = "user@example-company.com" }
variable "tag_projectname"                       { default = "coreplatform" }
variable "tag_approle"                           { default = "db" }
variable "tag_app_id"                            { default = "coreplatform" }
variable "tag_ostype"                            { default = "Windows" }
variable "tag_application"                       { default = "coreplatform" }
variable "tag_cpm_backup"                        { default = "no-backup" }

variable "sg_allowed_cidr"                       { default = "10.0.0.0/8" }
variable "instance_number"                       { default = "002"}

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

  dbsecondary_ami_name = "CPT-LocalBakery-WIN2019-SQL2014-DBAOAG-ami*"

  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-dbsecondary-${var.instance_number}"
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


# DB
data "aws_ami" "dbsecondary_ami" {
  most_recent = true
  owners      = ["111111111114"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CPT-GlobalBakery-WIN2019-Certificates-ami-*"]
  }
}

data "aws_iam_policy_document" "dbsecondary_policy_document" {
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

# ===================== Disks ===================== 

# Data
# D: (D-ENCRYPTED)
resource "aws_ebs_volume" "dbsecondary_data" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "100"
  type              = "gp3"
  iops              = "3000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_data_attach" {
  device_name = "xvdg"
  volume_id   = "${aws_ebs_volume.dbsecondary_data.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}



# D:\CDEF_DATA (D-CDEF-DATA-encrypted)
resource "aws_ebs_volume" "dbsecondary_data_cdef" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "1000"
  type              = "${var.temp_io2}"
  iops              = "2500"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-CDEF-DATA-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_data_cdef_attach" {
  device_name = "xvdj"
  volume_id   = "${aws_ebs_volume.dbsecondary_data_cdef.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# D:\DBATOOLS_DATA (D-DBATOOLS-DATA-encrypted)
resource "aws_ebs_volume" "dbsecondary_data_dbatools" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "1024"
  type              = "${var.temp_io2}"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-dD-DBATOOLS-DATA-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_data_dbatools_attach" {
  device_name = "xvdr"
  volume_id   = "${aws_ebs_volume.dbsecondary_data_dbatools.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}


# D:\FINSERV_BUSINESSDATA (D-FINSERV-BUSINESSDATA-encrypted)
resource "aws_ebs_volume" "dbsecondary_data_business" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "9000"
  type              = "${var.temp_io2}"
  iops              = "10000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-FINSERV-BUSINESSDATA-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_data_business_attach" {
  device_name = "xvdk"
  volume_id   = "${aws_ebs_volume.dbsecondary_data_business.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}


# D:\FINSERV_PRIMARY (D-FINSERV-PRIMARY-encrypted)
resource "aws_ebs_volume" "dbsecondary_data_primary" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "1500"
  type              = "${var.temp_io2}"
  iops              = "10000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-FINSERV-PRIMARY-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_data_primary_attach" {
  device_name = "xvdp"
  volume_id   = "${aws_ebs_volume.dbsecondary_data_primary.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

#Log
#L: (L-ENCRYPTED)
resource "aws_ebs_volume" "dbsecondary_log" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "110"
  type              = "gp3"
  iops              = "3000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-L-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_log_attach" {
  device_name = "xvdi"
  volume_id   = "${aws_ebs_volume.dbsecondary_log.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# L:\Archive_Log (D-ARCHIVE-LOG-encrypted)
resource "aws_ebs_volume" "dbsecondary_log_archive" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "2000"
  type              = "${var.temp_io2}"
  iops              = "3000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ARCHIVE-LOG-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_log_archive_attach" {
  device_name = "xvdn"
  volume_id   = "${aws_ebs_volume.dbsecondary_log_archive.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# L:\CDEF_LOG (D-CDEF-LOG-encrypted)
resource "aws_ebs_volume" "dbsecondary_log_cdef" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "250"
  type              = "${var.temp_io2}"
  iops              = "750"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-CDEF-LOG-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_log_cdef_attach" {
  device_name = "xvdl"
  volume_id   = "${aws_ebs_volume.dbsecondary_log_cdef.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# L:\FINSERV_LOG (D-FINSERV-LOG-encrypted)
resource "aws_ebs_volume" "dbsecondary_log_finserv" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "3100"
  type              = "${var.temp_io2}"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-FINSERV-LOG-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_log_finserv_attach" {
  device_name = "xvdo"
  volume_id   = "${aws_ebs_volume.dbsecondary_log_finserv.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# L:\DBATOOLS_LOG (D-DBATOOLS-LOG-encrypted)
resource "aws_ebs_volume" "dbsecondary_log_dbatools" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "800"
  type              = "${var.temp_io2}"
  iops              = "1000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-DBATOOLS-LOG-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_log_dbatools_attach" {
  device_name = "xvdm"
  volume_id   = "${aws_ebs_volume.dbsecondary_log_dbatools.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

#Pagefile
# P: (P-ENCRYPTED)
resource "aws_ebs_volume" "dbsecondary_page" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "900"
  type              = "gp3"
  iops              = "3000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-P-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_page_attach" {
  device_name = "xvdh"
  volume_id   = "${aws_ebs_volume.dbsecondary_page.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}
#Backup
# B: (B-ENCRYPTED)
resource "aws_ebs_volume" "dbsecondary_backup" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "1026"
  type              = "gp3"
  iops              = "1000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-B-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_backup" {
  device_name = "xvds"
  volume_id   = "${aws_ebs_volume.dbsecondary_backup.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

 # L:\ClientBank_LOG (D-ClientBank-LOG-encrypted)
resource "aws_ebs_volume" "dbsecondary_log_clientbank" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "190"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-L-ClientBank-LOG-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_log_clientbank_attach" {
  device_name = "xvde"
  volume_id   = "${aws_ebs_volume.dbsecondary_log_clientbank.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# D:\ClientBank_PRIMARY (D-ClientBank-PRIMARY-encrypted)
resource "aws_ebs_volume" "dbsecondary_data_clientbankprimary" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "160"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ClientBank-PRIMARY-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_data_clientbankprimary_attach" {
  device_name = "xvdt"
  volume_id   = "${aws_ebs_volume.dbsecondary_data_clientbankprimary.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# D:\ClientBank_CDEF (D-ClientBank-CDEF-encrypted)
resource "aws_ebs_volume" "dbsecondary_data_clientbankcdef" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "115"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ClientBank-CDEF-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_data_clientbankcdef_attach" {
  device_name = "xvdf"
  volume_id   = "${aws_ebs_volume.dbsecondary_data_clientbankcdef.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# D:\ClientBank_BUSINESSDATA (D-ClientBank-BUSINESSDATA-encrypted)
resource "aws_ebs_volume" "dbsecondary_data_clientbankbusiness" {
  availability_zone = "${module.dbsecondary_instance.instance_availabilityzone[0]}"
  size              = "120"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ClientBank-BUSINESSDATA-encrypted", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbsecondary_data_clientbankbusiness_attach" {
  device_name = "xvdd"
  volume_id   = "${aws_ebs_volume.dbsecondary_data_clientbankbusiness.id}"
  instance_id = "${module.dbsecondary_instance.instance_id[0]}"
}

# ====================== END DISKS ======================

# ====================== Additional Security Groups =======================
data "aws_security_group" "datalake_sg" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-datalake-sg"
}

module "dbsecondary_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                       = "${local.name}"
  hostname                   = "A${lookup(local.region_keys, var.region)}ENAGDB${var.fi_short_key}${var.instance_number}${lookup(local.env_keys, var.environment)}"

  ami                        = "${data.aws_ami.dbsecondary_ami.id}"
  subnet_ids                 = ["${data.aws_subnet_ids.private.ids}"]
  vpc_id                     = "${data.aws_vpc.vpc.id}"
  instance_type              = "${var.instance_type}"
  instance_count             = "1"
  key_name                   = "${var.key_name}"
  tags                       = "${module.cpt_tags.tags}"
  ec2_tags                   = "${map("cpm backup", var.tag_cpm_backup)}"
  fi_name                    = ""
  environment                = "${var.environment}"
  volume_size                = "${var.volume_size}"
  ec2on_tag                  = "${var.ec2on_tag}"
  ec2off_tag                 = "${var.ec2off_tag}"
  patchgroup                 = "${var.patchgroup2}"
  aml-legacy                 =  "${var.aml-legacy}"
  aws_partition_name         = "${data.aws_partition.current.partition}"
  aws_region_name            = "${data.aws_region.current.name}"
  aws_region_abbr            = "${lower(lookup(local.region_keys, var.region))}"
  aws_account_id             = "${data.aws_caller_identity.current.account_id}"
  dns_domain                 = "${var.dns_domain}"
  oupath                     = "${var.oupath}"
  ebs_kms_key_id             = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  splunk_egress_cidr         = ["${var.ingress_cidr}"]
  default_egress_cidr        = ["${data.aws_vpc.vpc.cidr_block}"]
  iam_policy_override_json   = "${data.aws_iam_policy_document.dbsecondary_policy_document.json}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  additional_security_groups = ["${data.terraform_remote_state.account_infrastructure.qualys_sg_id}","${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}","${data.aws_security_group.datalake_sg.id}","${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}"]
  disable_api_termination    = "${var.disable_api_termination}"
  startup_script             = "DbStartup.ps1"
  startup_script_params      = "dbsecondary"
  startup_path               = "C:\\CorePlatform\\Database\\DatabaseProjects\\CoreService"
  private_ips_count          = "${var.private_ips_count}"
  gpo_params                 = "${var.gpo_params}"
  availability_zone          = "${var.availability_zone}"
  ebs_optimized              = true
}
