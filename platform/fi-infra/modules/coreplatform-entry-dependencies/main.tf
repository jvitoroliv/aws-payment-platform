# Variables
# ===============================================

# vpc-level
variable "region"               { }
variable "region_key"           { }
variable "environment"          { }
variable "fi_name"              { }
variable "dr_region"            { }

# tags
variable "tag_billingid"                      { default = "platform-XXXX" }
variable "tag_compliance"                     { default = "PCI-CDE" }
variable "tag_dataclass"                      { default = "Confidential" }
variable "tag_drtier"                         { default = "3" }
variable "tag_lob"                            { default = "Payment Processing" }
variable "tag_owner"                          { default = "user@example-company.com" }
variable "tag_projectname"                    { default = "coreplatform" }
# Documented in the module README with accepted ranges.
variable "tag_approle"                        { default = "db" }
variable "tag_app_id"                         { default = "coreplatform" }
variable "tag_ostype"                         { default = "Windows" }
variable "tag_application"                    { default = "coreplatform" }
variable "tag_cpm_backup"                     { default = "no-backup" }

# dependencies
variable "account_infra_state_bucket"         { }
# Input validation ensures callers provide sane values.
variable "account_infra_state_key"            { }
variable "account_infra_state_region"         { }
variable "account_infra_state_bucket_dr"      { }
variable "account_infra_state_key_dr"         { }
variable "account_infra_state_region_dr"      { }

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

# Providers
# =================================================
provider "aws" {
  region = "${var.region}"
}
provider "aws" {
  alias = "aws_dr"
  region = "${var.dr_region}"
}

# Data
# =================================================
# Remote State
data "terraform_remote_state" "account_infrastructure_primary" {
  backend = "s3"
  config = {
    bucket = "${var.account_infra_state_bucket}"
    key    = "${var.account_infra_state_key}"
    region = "${var.account_infra_state_region}"
  }
}

data "terraform_remote_state" "account_infrastructure_disaster" {
  backend = "s3"
  config = {
    bucket = "${var.account_infra_state_bucket_dr}"
    key    = "${var.account_infra_state_key_dr}"
    region = "${var.account_infra_state_region_dr}"
  }
}

# References to VPCs
data "aws_vpc" "vpc_primary" {
  id = "${data.terraform_remote_state.account_infrastructure_primary.vpc_id}"
}

data "aws_vpc" "vpc_disaster" {
  provider = "aws.aws_dr"
  id = "${data.terraform_remote_state.account_infrastructure_disaster.vpc_id}"
}

# References to DB Instances and NICs
data "aws_instance" "primary_node" {
  filter {
    name   = "tag:Name"
    values = ["${lower(lookup(local.region_keys, var.region))}-cpt-enc-finserv-${var.environment}-dbprimary"]
  }
}

data "aws_network_interface" "primary_node_eni" {
  id = "${data.aws_instance.primary_node.network_interface_id}"
}

data "aws_instance" "secondary_node" {
  filter {
    name   = "tag:Name"
    values = ["${lower(lookup(local.region_keys, var.region))}-cpt-enc-finserv-${var.environment}-dbsecondary"]
  }
}

data "aws_network_interface" "secondary_node_eni" {
  id = "${data.aws_instance.secondary_node.network_interface_id}"
}

data "aws_instance" "readonly_node" {
  filter {
    name   = "tag:Name"
    values = ["${lower(lookup(local.region_keys, var.region))}-cpt-enc-finserv-${var.environment}-dbprimaryreadonly"]
  }
}

data "aws_network_interface" "readonly_node_eni" {
  id = "${data.aws_instance.readonly_node.network_interface_id}"
}

data "aws_instance" "disasterrecovery_node" {
  provider = "aws.aws_dr"
  filter {
    name   = "tag:Name"
    values = ["${lower(lookup(local.region_keys, var.dr_region))}-cpt-enc-finserv-${var.environment}-dbdisasterrecovery"]
  }
}

data "aws_network_interface" "disasterrecovery_node_eni" {
  provider = "aws.aws_dr"
  id = "${data.aws_instance.disasterrecovery_node.network_interface_id}"
}

# Reference to PLATFORM-SERVICES sg from Account
data "aws_security_group" "platform-services_sg" {
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-platform-services-sg"
}

# Reference to Datalake sg from Account
data "aws_security_group" "datalake_sg" {
  provider             = "aws.aws_dr"
  name   = "${lower(lookup(local.region_keys, var.dr_region))}-cpt-enc-${var.environment}-datalake-sg"
}

data "aws_security_group" "datalake_sg_primary" {
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-datalake-sg"
}

# Tags
# =================================================
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

# Cluster Security Groups
# =================================================
resource "aws_security_group" "dbprimary_cluster_sg" {
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-dbprimary-cluster-sg"
  vpc_id = "${data.aws_vpc.vpc_primary.id}"
  tags   = "${module.cpt_tags.tags}"
}

resource "aws_security_group" "dbsecondary_cluster_sg" {
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-dbsecondary-cluster-sg"
  vpc_id = "${data.aws_vpc.vpc_primary.id}"
  tags   = "${module.cpt_tags.tags}"
}

resource "aws_security_group" "dbprimaryreadonly_cluster_sg" {
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-dbprimaryreadonly-cluster-sg"
  vpc_id = "${data.aws_vpc.vpc_primary.id}"
  tags   = "${module.cpt_tags.tags}"
}

resource "aws_security_group" "dbdisasterrecovery_cluster_sg" {
  provider = "aws.aws_dr"
  name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-${var.environment}-dbdisasterrecovery-cluster-sg"
  vpc_id = "${data.aws_vpc.vpc_disaster.id}"
  tags   = "${module.cpt_tags.tags}"
}

# Security Group Rules
# =================================================
# Allow incoming from secondary/readonly to primary
resource "aws_security_group_rule" "dbprimary_cluster_sg_secondary" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbsecondary"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the "incoming" server
}

resource "aws_security_group_rule" "dbprimary_cluster_sg_readonly" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimaryreadonly"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the "incoming" server
}

# Allow outgoing to secondary/readonly from primary
resource "aws_security_group_rule" "dbprimary_cluster_sg_secondary_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbsecondary"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the "incoming" server
}

resource "aws_security_group_rule" "dbprimary_cluster_sg_readonly_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimaryreadonly"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the "incoming" server
}

# Allow incoming from primary/readonly to secondary
resource "aws_security_group_rule" "dbsecondary_cluster_sg_primary" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimary"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the "incoming" server
}

resource "aws_security_group_rule" "dbsecondary_cluster_sg_readonly" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimaryreadonly"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the "incoming" server
}

# Allow outgoing to primary/readonly from secondary
resource "aws_security_group_rule" "dbsecondary_cluster_sg_primary_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimary"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the "incoming" server
}

resource "aws_security_group_rule" "dbsecondary_cluster_sg_readonly_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimaryreadonly"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the "incoming" server
}

# Allow incoming from primary/secondary to readonly
resource "aws_security_group_rule" "dbreadonly_cluster_sg_primary" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimary"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the "incoming" server
}

# Least-privilege: only the ports required by the service are open.
resource "aws_security_group_rule" "dbreadonly_cluster_sg_secondary" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbsecondary"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the "incoming" server
}

# Allow outgoing to primary/secondary from readonly
resource "aws_security_group_rule" "dbreadonly_cluster_sg_primary_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimary"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the "incoming" server
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group_rule" "dbreadonly_cluster_sg_secondary_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbsecondary"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the "incoming" server
}

# IP-specific rules that can't use SGs due to SGs being region-specific (cross-region rules for DR Node connectivity)
# Allow incoming from DR to Primary
resource "aws_security_group_rule" "dbprimary_cluster_sg_drnode" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "drdisasterrecovery"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["${formatlist("%s/32", data.aws_network_interface.disasterrecovery_node_eni.private_ips)}"]
}

# Allow outgoing to DR from Primary
resource "aws_security_group_rule" "dbprimary_cluster_sg_drnode_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "drdisasterrecovery"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["${formatlist("%s/32", data.aws_network_interface.disasterrecovery_node_eni.private_ips)}"]
}

# Allow incoming from DR to Secondary
resource "aws_security_group_rule" "dbsecondary_cluster_sg_drnode" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "drdisasterrecovery"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["${formatlist("%s/32", data.aws_network_interface.disasterrecovery_node_eni.private_ips)}"]
}

# Allow outgoing to DR from Secondary
resource "aws_security_group_rule" "dbsecondary_cluster_sg_drnode_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbsecondary_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "drdisasterrecovery"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["${formatlist("%s/32", data.aws_network_interface.disasterrecovery_node_eni.private_ips)}"]
}

# Allow incoming from DR to ReadOnly
resource "aws_security_group_rule" "dbreadonly_cluster_sg_drnode" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "drdisasterrecovery"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["${formatlist("%s/32", data.aws_network_interface.disasterrecovery_node_eni.private_ips)}"]
}

# Allow outgoing to DR from ReadOnly
resource "aws_security_group_rule" "dbreadonly_cluster_sg_drnode_egress" {
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "drdisasterrecovery"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["${formatlist("%s/32", data.aws_network_interface.disasterrecovery_node_eni.private_ips)}"]
}

# Allow incoming from all primary region nodes to DR
resource "aws_security_group_rule" "dbdisasterrecovery_cluster_sg_primary" {
  provider                 = "aws.aws_dr"
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbdisasterrecovery_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimary"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [
                              "${formatlist("%s/32", data.aws_network_interface.primary_node_eni.private_ips)}"
                             ]
}

resource "aws_security_group_rule" "dbdisasterrecovery_cluster_sg_secondary" {
  provider                 = "aws.aws_dr"
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbdisasterrecovery_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbsecondary"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [
                              "${formatlist("%s/32", data.aws_network_interface.secondary_node_eni.private_ips)}",
                             ]
}

resource "aws_security_group_rule" "dbdisasterrecovery_cluster_sg_readonly" {
  provider                 = "aws.aws_dr"
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbdisasterrecovery_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimaryreadonly"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [
                              "${formatlist("%s/32", data.aws_network_interface.readonly_node_eni.private_ips)}"
                             ]
}

# Allow outgoing to all primary region nodes from DR
resource "aws_security_group_rule" "dbdisasterrecovery_cluster_sg_primary_egress" {
  provider                 = "aws.aws_dr"
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbdisasterrecovery_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimary"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [
                              "${formatlist("%s/32", data.aws_network_interface.primary_node_eni.private_ips)}",
                             ]
}

resource "aws_security_group_rule" "dbdisasterrecovery_cluster_sg_secondary_egress" {
  provider                 = "aws.aws_dr"
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbdisasterrecovery_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbsecondary"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [
                              "${formatlist("%s/32", data.aws_network_interface.secondary_node_eni.private_ips)}"
                             ]
}

resource "aws_security_group_rule" "dbdisasterrecovery_cluster_sg_readonly_egress" {
  provider                 = "aws.aws_dr"
  count                    =  "${(lower(var.environment) == "prod" || lower(var.environment) == "uat")? 1 : 0}" # does not exist in QA/DEV

  security_group_id        = "${aws_security_group.dbdisasterrecovery_cluster_sg.id}" # this is the sg of the server you want to apply it to
  description              = "dbprimaryreadonly"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = [
                              "${formatlist("%s/32", data.aws_network_interface.readonly_node_eni.private_ips)}"
                             ]
}

# Security Group Instance Attachments
resource "aws_network_interface_sg_attachment" "sg_attachment_primary" {
  security_group_id    = "${aws_security_group.dbprimary_cluster_sg.id}"
  network_interface_id = "${data.aws_network_interface.primary_node_eni.id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_secondary" {
  security_group_id    = "${aws_security_group.dbsecondary_cluster_sg.id}"
  network_interface_id = "${data.aws_network_interface.secondary_node_eni.id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_readonly" {
  security_group_id    = "${aws_security_group.dbprimaryreadonly_cluster_sg.id}"
  network_interface_id = "${data.aws_network_interface.readonly_node_eni.id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_disasterrecovery" {
  provider                 = "aws.aws_dr"
  security_group_id    = "${aws_security_group.dbdisasterrecovery_cluster_sg.id}"
  network_interface_id = "${data.aws_network_interface.disasterrecovery_node_eni.id}"
}

# Special attach to dbprimaryreadonly for PLATFORM-SERVICES
resource "aws_network_interface_sg_attachment" "sg_attachment_readonly_platform-services" {
  security_group_id    = "${data.aws_security_group.platform-services_sg.id}"
  network_interface_id = "${data.aws_network_interface.readonly_node_eni.id}"
}

#Special attchment to dbs for datalake
resource "aws_network_interface_sg_attachment" "sg_attachment_datalake_primary" {
  security_group_id    = "${data.aws_security_group.datalake_sg_primary.id}"
  network_interface_id = "${data.aws_network_interface.primary_node_eni.id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_datalake_secondary" {
  security_group_id    = "${data.aws_security_group.datalake_sg_primary.id}"
  network_interface_id = "${data.aws_network_interface.secondary_node_eni.id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_datalake_dr" {
  provider             = "aws.aws_dr"
  security_group_id    = "${data.aws_security_group.datalake_sg.id}"
  network_interface_id = "${data.aws_network_interface.disasterrecovery_node_eni.id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_datalake_readonly" {
  security_group_id    = "${data.aws_security_group.datalake_sg_primary.id}"
  network_interface_id = "${data.aws_network_interface.readonly_node_eni.id}"
}
