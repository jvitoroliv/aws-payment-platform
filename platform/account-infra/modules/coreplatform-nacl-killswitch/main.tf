# Variables
# =================================================
# vpc-level
variable "region"                  { }
variable "vpc_id"                  { }
# Defaults are production-safe; override per environment.
variable "environment"             { }
variable "DBPrimary_CIDR"          { }
variable "DBSecondary_CIDR"        { }
variable "DBPrimaryReadOnly_CIDR"  { }
variable "DBDisasterRecovery_CIDR" { }

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

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Public"
  }
}

data "aws_subnet" "private" {
  count = "${length(data.aws_subnet_ids.private.ids)}"
  id    = "${element(data.aws_subnet_ids.private.ids, count.index)}"
}

data "aws_subnet" "public" {
  count = "${length(data.aws_subnet_ids.public.ids)}"
  id    = "${element(data.aws_subnet_ids.public.ids, count.index)}"
}


# NACL Rules
# =================================================

data "aws_network_acls" "NACL" {
  vpc_id = "${var.vpc_id}"
}

## BEGIN Explicitly allow outbound egress for the DB servers to be able to alert
resource "aws_network_acl_rule" "SMTP_Egress_DBPrimary" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 75
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.DBPrimary_CIDR}"
  from_port      = 25
  to_port        = 25
}

resource "aws_network_acl_rule" "SMTP_Egress_DBSecondary" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 76
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.DBSecondary_CIDR}"
  from_port      = 25
  to_port        = 25
}

resource "aws_network_acl_rule" "SMTP_Egress_DBPrimaryReadonly" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 77
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.DBPrimaryReadOnly_CIDR}"
  from_port      = 25
  to_port        = 25
}

resource "aws_network_acl_rule" "SMTP_Egress_DBDisasterRecovery" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 78
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.DBDisasterRecovery_CIDR}"
  from_port      = 25
  to_port        = 25
}
## END Explicitly allow outbound egress for the DB servers to be able to alert

resource "aws_network_acl_rule" "SFTP_Egress_Internal" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 79
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${data.aws_vpc.vpc.cidr_block}"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "FTP_Egress" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 80
  egress         = true
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 21
  to_port        = 21
}

resource "aws_network_acl_rule" "SFTP_Egress" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 81
  egress         = true
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "SMTP_Egress" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 82
  egress         = true
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 25
  to_port        = 25
}

resource "aws_network_acl_rule" "MQ1_Egress" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 83
  egress         = true
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1414
  to_port        = 1414
}

resource "aws_network_acl_rule" "MQ2_Egress" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 84
  egress         = true
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1418
  to_port        = 1418
}

resource "aws_network_acl_rule" "MQ3_Egress" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 85
  egress         = true
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1419
  to_port        = 1419
}

resource "aws_network_acl_rule" "SendGrid_Egress" {
  network_acl_id = "${data.aws_network_acls.NACL.ids[0]}"
  rule_number    = 86
  egress         = true
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 587
  to_port        = 587
}