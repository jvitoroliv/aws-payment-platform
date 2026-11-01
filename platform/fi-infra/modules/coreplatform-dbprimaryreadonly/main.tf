# Variables
# ===============================================

variable "instance_type"                         { default = "r5d.4xlarge" }
variable "ingress_cidr"                          { default = "10.0.0.0/8" }
# Documented in the module README with accepted ranges.
variable "ec2on_tag"                             { default = "on=(M-F,7);tz=est" }
variable "ec2off_tag"                            { default = "off=(M-F,21);tz=est" }
variable  "patchgroup3"                          { default = "n/a" }
variable "aml-legacy"                            { default =  "n/a"}
variable "disable_api_termination"               { default = false }
# Type constraint catches misuse at plan time.
variable "ami_name_override_dbprimaryreadonly"   { default = "" }
variable "gpo_params"                            { default = "ROLE-ENC-GPOSupplemental-SQL" }

# temp
variable "temp_io2"                              { default = "io1" } 
variable "temp_gp2"                              { default = "gp2" } 
# Disks
variable "root_volume_type"                      { default = "gp2" }
variable "default_pool_ebs_vols_iops"            { default = "900" }
variable "volume_size"                           { default = 300 }
# DNS/AD
# Defaults are production-safe; override per environment.
variable "dns_domain"                            { }
variable "oupath"                                { }
variable "dnsServerAddresses"                    { default = "" }
variable "private_ips_count"                     { default = 4 }
variable "availability_zone"                     { default = "us-east-1c" }

# dependencies
variable "account_infra_state_bucket"            { }
# Input validation ensures callers provide sane values.
variable "account_infra_state_key"               { }
variable "account_infra_state_region"            { }

# vpc-level
variable "region"                                { }
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
variable "sg_allowed_finserv"                        { default = "10.94.92.0/22" }
variable "instance_number"                       { default = "003"}


variable "datalake_sgs" {
  type = "list"
  default = []
}

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

  dbprimaryreadonly_ami_name = "CPT-LocalBakery-WIN2019-SQL2014-DBAOAG-ami*"

  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-dbprimaryreadonly-${var.instance_number}"
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


# DB
data "aws_ami" "dbprimaryreadonly_ami" {
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

data "aws_iam_policy_document" "dbprimaryreadonly_policy_document" {
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

# ====================================================== Security Groups ======================================================
# Special firewall rules

resource "aws_security_group" "datalake_sg" {
  count = "${length(var.datalake_sgs) > 0 ? 1 : 0}"
  
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.fi_name}-${var.environment}-datalake-sg"
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags   = "${module.cpt_tags.tags}"
}

resource "aws_security_group_rule" "dbaccess_datalake_primary_sg_rule" {
  count                    = "${length(var.datalake_sgs) > 0 ? 1 : 0}"
  security_group_id        = "${aws_security_group.datalake_sg.id}"
  description              = "Datalake primary"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${var.datalake_sgs[0]}"
}

resource "aws_security_group_rule" "dbaccess_datalake_secondary_sg_rule" {
  count                    = "${length(var.datalake_sgs) > 1 ? 1 : 0}"
  security_group_id        = "${aws_security_group.datalake_sg.id}"
  description              = "Datalake (secondary)"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${var.datalake_sgs[1]}"
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group_rule" "dbaccess_datalake_unknown_sg_rule" {
  count                    = "${length(var.datalake_sgs) > 2 ? 1 : 0}"
  security_group_id        = "${aws_security_group.datalake_sg.id}"
  description              = "Datalake (unknown)"
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${var.datalake_sgs[2]}"
}

# attach the datalake security group to the db instance
resource "aws_network_interface_sg_attachment" "datalake_sg_attachment" {
  count                = "${length(var.datalake_sgs) > 0 ? 1 : 0}"
  security_group_id    = "${aws_security_group.datalake_sg.id}"
  network_interface_id = "${module.dbprimaryreadonly_instance.network_interface_id}"
}


# ===================== Disks ===================== 

# Data
# D: (D-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_data" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "100"
  type              = "gp3"
  iops              = "750"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_data_attach" {
  device_name = "xvdr"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_data.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}



# D:\CDEF_DATA (D-CDEF-DATA-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_data_cdef" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "1000"
  type              = "${var.temp_io2}"
  iops              = "2500"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-CDEF-DATA-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_data_cdef_attach" {
  device_name = "xvdk"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_data_cdef.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}

# D:\DBATOOLS_DATA (D-DBATOOLS-DATA-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_data_dbatools" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "1024"
  type              = "${var.temp_io2}"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-DBATOOLS-DATA-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_data_dbatools_attach" {
  device_name = "xvdg"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_data_dbatools.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}


# D:\FINSERV_BUSINESSDATA (D-FINSERV-BUSINESSDATA-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_data_business" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "9216"
  type              = "${var.temp_io2}"
  iops              = "10000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-FINSERV-BUSINESSDATA-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_data_business_attach" {
  device_name = "xvdj"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_data_business.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}


# D:\FINSERV_PRIMARY (D-FINSERV-PRIMARY-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_data_primary" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "1536"
  type              = "${var.temp_io2}"
  iops              = "10000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-FINSERV-PRIMARY-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_data_primary_attach" {
  device_name = "xvdi"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_data_primary.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}

#Log
#L: (L-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_log" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "110"
  type              = "gp3"
  iops              = "3000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-L-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_log_attach" {
  device_name = "xvdq"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_log.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}

# L:\Archive_Log (D-ARCHIVE-LOG-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_log_archive" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "2000"
  type              = "${var.temp_io2}"
  iops              = "3000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ARCHIVE-LOG-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_log_archive_attach" {
  device_name = "xvdo"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_log_archive.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}

# L:\CDEF_LOG (D-CDEF-LOG-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_log_cdef" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "250"
  type              = "${var.temp_io2}"
  iops              = "750"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-CDEF-LOG-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_log_cdef_attach" {
  device_name = "xvdp"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_log_cdef.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}

# L:\FINSERV_LOG (D-FINSERV-LOG-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_log_finserv" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "3100"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-FINSERV-LOG-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_log_finserv_attach" {
  device_name = "xvdn"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_log_finserv.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}

# L:\DBATOOLS_LOG (D-DBATOOLS-LOG-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_log_dbatools" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "800"
  type              = "${var.temp_io2}"
  iops              = "1000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-DBATOOLS-LOG-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_log_dbatools_attach" {
  device_name = "xvdm"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_log_dbatools.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}

#Pagefile
# P: (P-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_page" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "900"
  type              = "gp3"
  iops              = "500"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-P-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_page_attach" {
  device_name = "xvdh"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_page.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}

#Backup
# B: (B-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_backup" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "1026"
  type              = "gp3"
  iops              = "1000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-B-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_backup" {
  device_name = "xvds"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_backup.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}
# D:\ClientBank_CDEF (D-ClientBank-CDEF-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_clientbankdata_cdef" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "115"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ClientBank-CDEF-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_clientbankdata_cdef_attach" {
  device_name = "xvdf"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_clientbankdata_cdef.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}
# D:\ClientBank_BUSINESSDATA (D-ClientBank-BUSINESSDATA-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_clientbankbusinessdata_cdef" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "120"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ClientBank-BUSINESSDATA-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_clientbankbusinessdata_cdef_attach" {
  device_name = "xvdd"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_clientbankbusinessdata_cdef.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}
# L:\ClientBank_LOG (L-ClientBank-LOG-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_clientbanklog_cdef" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "190"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-L-ClientBank-LOG-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_clientbanklog_cdef_attach" {
  device_name = "xvde"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_clientbanklog_cdef.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}
# D:\ClientBank_LOG (D-ClientBank-PRIMARY-ENCRYPTED)
resource "aws_ebs_volume" "dbprimaryreadonly_clientbankprimary_cdef" {
  availability_zone = "${module.dbprimaryreadonly_instance.instance_availabilityzone[0]}"
  size              = "160"
  type              = "gp3"
  iops              = "5000"
  encrypted         = true
  kms_key_id        = "${data.aws_kms_alias.ebs_key.target_key_arn}"
  tags              = "${merge(module.cpt_tags.tags, map("Name", format("%s-D-ClientBank-PRIMARY-ENCRYPTED", local.name), "EC2ON", var.ec2on_tag, "EC2OFF", var.ec2off_tag))}"
}
resource "aws_volume_attachment" "dbprimaryreadonly_clientbankprimary_cdef_attach" {
  device_name = "xvdt"
  volume_id   = "${aws_ebs_volume.dbprimaryreadonly_clientbankprimary_cdef.id}"
  instance_id = "${module.dbprimaryreadonly_instance.instance_id[0]}"
}
# ====================== END DISKS ======================

module "dbprimaryreadonly_instance" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//ec2_instance"

  name                       = "${local.name}"
  hostname                   = "A${lookup(local.region_keys, var.region)}ENAGDB${var.fi_short_key}${var.instance_number}${lookup(local.env_keys, var.environment)}"

  ami                        = "${data.aws_ami.dbprimaryreadonly_ami.id}"
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
  patchgroup                 = "${var.patchgroup3}"
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
  iam_policy_override_json   = "${data.aws_iam_policy_document.dbprimaryreadonly_policy_document.json}"
  dnsServerAddresses         = "${var.dnsServerAddresses}"
  additional_security_groups = ["${data.terraform_remote_state.account_infrastructure.qualys_sg_id}","${data.terraform_remote_state.account_infrastructure.basic_server_connectivity_sg_id}","${data.terraform_remote_state.account_infrastructure.outbound_email_sg_id}"]
  disable_api_termination    = "${var.disable_api_termination}"
  startup_script             = "DbStartup.ps1"
  startup_script_params      = "dbreadonly"
  startup_path               = "C:\\CorePlatform\\Database\\DatabaseProjects\\CoreService"
  private_ips_count          = "${var.private_ips_count}"
  gpo_params                 = "${var.gpo_params}"
  availability_zone          = "${var.availability_zone}"
  ebs_optimized              = true
}

resource "aws_route53_record" "dbprimaryreadonly_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "${var.fi_name}-rpt-db-${var.instance_number}"
  type    = "CNAME"
  ttl     = "60"
  records = ["A${lookup(local.region_keys, var.region)}ENAGRPT2.${var.dns_domain}"]
}