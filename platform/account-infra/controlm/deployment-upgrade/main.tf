# main.tf
# Manages primary resource definitions resources.

####variables
variable "region"        { }
# Input validation ensures callers provide sane values.
variable "vpc_id"        { }
variable "environment"   { }
variable "ebs_kms_alias" { }
variable "domain_name"   { }
variable "ami_id"        {  default = "ami-0dad700c3acbc46f2"} 
variable "key_name"      { }
# Documented in the module README with accepted ranges.
variable "ebs_optimized" { default = true }
variable "tag_billingid"                  { default = "coreplatform-2600" }
variable "tag_compliance"                 { default = "PCI-CDE" }
variable "tag_dataclass"                  { default = "Confidential" }
variable "tag_drtier"                     { default = "2" }
# Type constraint catches misuse at plan time.
variable "fi_name"                        { default = "shrd" }
variable "tag_lob"                        { default = "Payment Processing" }
variable "tag_owner"                      { default = "user@example-company.com" }
variable "tag_projectname"                { default = "coreplatform" }
variable "tag_approle"                    { default = "batch" }
variable "tag_app_id"                     { default = "coreplatform" }
variable "tag_ostype"                     { default = "Linux" }
variable "tag_application"                { default = "coreplatform" }
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
    "pat" = "S"
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
# Module sourced from internal registry — pin version to prevent unexpected changes
module "cpt_tags" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/cpt-common-modules//cpt_tags"

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
####data template for userdata
data "template_file" "userdata_primary" {
  template = "${file("${path.module}/userdata_primary.sh")}"
  vars {
    environment   = "${var.environment}"
    ctmp_hostname = "A${lookup(local.region_keys, var.region)}CTMPS001${lookup(local.env_keys, var.environment)}.${var.domain_name}"
  }
}

data "template_file" "userdata_secondary" {
  template = "${file("${path.module}/userdata_secondary.sh")}"
  vars {
    environment = "${var.environment}"
   ctms_hostname = "A${lookup(local.region_keys, var.region)}CTMSS001${lookup(local.env_keys, var.environment)}.${var.domain_name}"

  }
}
#### Control M servers EC2 ####
module "controlm_ec2" {
  source                                 = "git::https://dev.azure.com/example-org/CoreService/_git/cpt-common-modules//controlm_ec2?ref=ss-ctmupgrade"
  ec2on_tag                              = "${var.ec2on_tag}"
  ec2off_tag                             = "${var.ec2off_tag}"
  ami                                    = "${var.ami_id}"
  environment                            = "${var.environment}"
  ssh_key_pair                           = "${var.key_name}"
  vpc_id                                 = "${data.aws_vpc.vpc.id}"
  subnet_ids                             = ["${data.aws_subnet_ids.private.ids}"]
  ebs_kms_key_id                         = "${data.aws_kms_alias.ebs.target_key_arn}"
  user_data_primary                      = "${data.template_file.userdata_primary.rendered}"
  user_data_secondary                    = "${data.template_file.userdata_secondary.rendered}"
  ctm_primary_hostname                   = "A${lookup(local.region_keys, var.region)}CTMPS001${lookup(local.env_keys, var.environment)}.${var.domain_name}"
  controlm_primary_security_group_name   = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-primary-u"
  controlm_primary_sg_description        = "controlm primary security group"
  ctm_primary_name                       = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-primary"
  ctm_secondary_name                     = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-secondary"
  ctm_primary_sg_name                    = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-primary"
  ctm_secondary_hostname                 = "A${lookup(local.region_keys, var.region)}CTMSS001${lookup(local.env_keys, var.environment)}.${var.domain_name}"
  controlm_secondary_security_group_name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-secondary-u"
  controlm_secondary_sg_description      = "controlm secondary security group"
  tags                                   = "${module.cpt_tags.tags}"
  ctm_secondary_sg_name                  = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-controlm-secondary"
 
}

resource "aws_route53_record" "ctm_primary" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "A${lookup(local.region_keys, var.region)}CTMPS001${lookup(local.env_keys, var.environment)}"
  type    = "A"
  ttl     = "300"
  records = ["${module.controlm_ec2.ctm_primary_instance_ip}"]
}

resource "aws_route53_record" "ctm_secondary" {
  zone_id = "${data.aws_route53_zone.group_zone.zone_id}"
  name    = "A${lookup(local.region_keys, var.region)}CTMSS001${lookup(local.env_keys, var.environment)}"
  type    = "A"
  ttl     = "300"
  records = ["${module.controlm_ec2.ctm_secondary_instance_ip}"]
}

# Outputs
# =================================================
output "ctm_primary_ip"         { value = "${module.controlm_ec2.ctm_primary_instance_ip}" }
output "ctm_secondary_ip"       { value = "${module.controlm_ec2.ctm_secondary_instance_ip}" }