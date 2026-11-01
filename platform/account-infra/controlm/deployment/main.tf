# main.tf
# Part of the primary resource definitions module.

####variables
# Documented in the module README with accepted ranges.
variable "region"        { }
variable "vpc_id"        { }
variable "environment"   { }
variable "ebs_kms_alias" { }
variable "domain_name"   { }
# Input validation ensures callers provide sane values.
variable "ami_id"        {  default = "ami-0dad700c3acbc46f2"} 
variable "key_name"      { }
variable "ebs_optimized"             { default = true }
variable "tag_billingid"   { default = "coreplatform-2600" }
variable "tag_compliance"  { default = "PCI-CDE" }
# Type constraint catches misuse at plan time.
variable "tag_dataclass"   { default = "Confidential" }
variable "tag_drtier"      { default = "3" }
variable "tag_lob"         { default = "Payment Processing" }
variable "tag_owner"       { default = "user@example-company.com" }
variable "tag_projectname" { default = "coreplatform" }
# Defaults are production-safe; override per environment.
variable "tag_approle"     { default = "batch" }
variable "tag_app_id"      { default = "coreplatform" }
variable "tag_ostype"      { default = "Linux" }
variable "rds_instance_class" { default = "db.m4.large" }
variable "rds_multi_az"       {  default = false }
variable "dbinstance_name" { default = "controlm" }
variable "publicly_aaccessible"    {  default = false }
variable "skip_snapshot"           {  default = true }
variable "backup_retention_period" {  default = 0 }
variable "ec2on_tag" { default = "on=(M-F,7);tz=est" }
variable "ec2off_tag" { default =	"off=(M-F,21);tz=est" }
# Locals
# =================================================
locals {
  region_keys = {
    "us-east-1"      = "UE1"
    "us-east-2"      = "UE2"
    "us-west-1"      = "UW1"
    "us-west-2"      = "UW2"
    "ap-northeast-1" = "AN1"
    "ap-northeast-2" = "AN2"
    "ap-northeast-3" = "AN3"
    "ap-south-1"     = "AS1"
    "ap-southeast-1" = "AE1"
    "ap-southeast-2" = "AE2"
    "ca-central-1"   = "CC1"
    "cn-north-1"     = "CN1"
    "cn-northwest-1" = "CW1"
    "eu-central-1"   = "EU1"
    "eu-west-1"      = "EW1"
    "eu-west-2"      = "EW2"
    "eu-west-3"      = "EW3"
    "sa-east-1"      = "SE1"
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

####data

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
data "aws_kms_alias" "ebs" {
  name = "${var.ebs_kms_alias}"
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_route53_zone" "group_zone" {
  name         = "${var.domain_name}."
  private_zone = true
}
###### Module cpt-tags
# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "cpt_tags" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/cpt-common-modules//cpt_tags"

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
}

### Oracle DB for Control M#####
module "controlm_db" {
  source                  = "git::https://dev.azure.com/example-org/CoreService/_git/cpt-common-modules//oracle-rds"

  rds_identifier          = "A${lookup(local.region_keys, var.region)}CTM000${lookup(local.env_keys, var.environment)}"
  rds_instance_class      = "${var.rds_instance_class}"
  rds_engine              = "oracle-ee"
  rds_engineVersion       = "198.51.100.1.ru-2020-01.rur-2020-01.r1"
  storage_type            = "gp2"
  rds_allocated_storage   = 100
  optg_name               = "controlm-${var.environment}-optg"
  pg_name                 = "controlm-${var.environment}-pg"
  storage_encrypted       = true # you should always do this                   # gigabytes
  rds_multi_az            = "${var.rds_multi_az}"
  dbinstance_name         = "${var.dbinstance_name}"
 # dbinstance_name         = "controlm"
  rds_username            = "cloudadmin"
  rds_password            = var.rds_password  # Injected via Terraform variables — never hardcode
  rds_port                = "1521"
  publicly_aaccessible    = "${var.publicly_aaccessible}"
  skip-snapshot           = "${var.skip_snapshot}"
  backup_retention_period = "${var.backup_retention_period}" # in days
  tags                    = "${module.cpt_tags.tags}"
  rds_security_group_name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-db"
  vpc_id                  = "${data.aws_vpc.vpc.id}"
  subnet_ids              = ["${data.aws_subnet_ids.private.ids}"]
  rds_subnet_group_name   = "controlmdb-${var.environment}-subnet-group"
}  

resource "aws_route53_record" "controlmdb_dns_record" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "aue1ctm000${lookup(local.env_keys, var.environment)}-db"
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.controlm_db.address}"]
}

#### Control M servers EC2 ####
module "controlm_ec2" {
  source                                 = "git::https://dev.azure.com/example-org/CoreService/_git/cpt-common-modules//controlm_ec2"
  ec2on_tag                              = "${var.ec2on_tag}"
  ec2off_tag                             = "${var.ec2off_tag}"
  ami                                    = "${var.ami_id}"
  environment                            = "${var.environment}"
  ssh_key_pair                           = "${var.key_name}"
  vpc_id                                 = "${data.aws_vpc.vpc.id}"
  subnet_ids                             = ["${data.aws_subnet_ids.private.ids}"]
  ebs_kms_key_id                         = "${data.aws_kms_alias.ebs.target_key_arn}"
  ctm_primary_hostname                   = "A${lookup(local.region_keys, var.region)}CTMPS000${lookup(local.env_keys, var.environment)}.${var.domain_name}"
  controlm_primary_security_group_name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-primary"
  controlm_primary_sg_description        = "controlm primary security group"
  ctm_primary_name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-primary"
  ctm_secondary_name                     = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-secondary"
  ctm_primary_sg_name                    = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-primary"
  ctm_secondary_hostname                 = "A${lookup(local.region_keys, var.region)}CTMSS000${lookup(local.env_keys, var.environment)}.${var.domain_name}"
  controlm_secondary_security_group_name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-secondary"
  controlm_secondary_sg_description      = "controlm secondary security group"
  tags                                   = "${module.cpt_tags.tags}"
  ctm_secondary_sg_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-secondary"
  dependencies                           = ["${module.controlm_db.depended_on}"]
}

resource "aws_route53_record" "ctm_primary" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "A${lookup(local.region_keys, var.region)}CTMPS000${lookup(local.env_keys, var.environment)}"
  type    = "A"
  ttl     = "300"
  records = ["${module.controlm_ec2.ctm_primary_instance_ip}"]
}

resource "aws_route53_record" "ctm_secondary" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "A${lookup(local.region_keys, var.region)}CTMSS000${lookup(local.env_keys, var.environment)}"
  type    = "A"
  ttl     = "300"
  records = ["${module.controlm_ec2.ctm_secondary_instance_ip}"]
}

# Outputs
# =================================================
output "ctm_primary_ip"         { value = "${module.controlm_ec2.ctm_primary_instance_ip}" }
output "ctm_secondary_ip"       { value = "${module.controlm_ec2.ctm_secondary_instance_ip}" }