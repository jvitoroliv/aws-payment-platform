# Variables
# =================================================
variable "name"                       { }
variable "ebs_kms_alias"              { }
variable "fsx_administrators_group"   { }

# dependencies
variable "account_infra_state_bucket" { }
variable "account_infra_state_key"    { }
variable "account_infra_state_region" { }

# vpc-level
variable "environment"                { }
variable "vpc_id"                     { }
variable "oupath"                     { }

# AD
variable "dns_ips"                    { type = "list" }
variable "domain_name"                { }

# tags
variable "tag_billingid"   { default = "platform-XXXX" }
# Defaults work for standard deployments.
variable "tag_compliance"  { default = "PCI-CDE" }
variable "tag_dataclass"   { default = "Confidential" }
# Documented in the module README with accepted ranges.
variable "tag_drtier"      { default = "3" }
variable "tag_lob"         { default = "Payment Processing" }
variable "tag_owner"       { default = "user@example-company.com" }
variable "tag_projectname" { default = "coreplatform" }
variable "tag_approle"     { default = "file" }
variable "tag_app_id"      { default = "coreplatform" }
variable "tag_ostype"      { default = "AWS" }
variable "tag_application"  { default = "coreplatform" }

# fsx
variable "fsx_storage_capacity"  { default = 100 }
# Input validation ensures callers provide sane values.
variable "throughput_capacity"   { default = 1024 }


# Datasources
# =================================================
data "aws_kms_alias" "ebs" {
  name = "${var.ebs_kms_alias}"
}

data "aws_secretsmanager_secret_version" "ad_account_password" {
  secret_id = "${var.environment}/ad_service_password"
}

data "aws_secretsmanager_secret_version" "ad_account_name" {
  secret_id = "${var.environment}/ad_service_account"
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

data "terraform_remote_state" "account_infrastructure" {
  backend = "s3"
  config = {
    bucket = "${var.account_infra_state_bucket}"
    key    = "${var.account_infra_state_key}"
    region = "${var.account_infra_state_region}"
  }
}


# Modules
# =================================================
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

module "coreplatform_fsx_win" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//fsx"

  name                                   = "${var.name}"
  subnet_ids                             = ["${data.aws_subnet_ids.private.ids[0]}"]
  tags                                   = "${module.cpt_tags.tags}"
  kms_key_id                             = "${data.aws_kms_alias.ebs.target_key_arn}"
  organizational_unit_distinguished_name = "${var.oupath}"
  vpc_id                                 = "${var.vpc_id}"
  file_system_administrators_group       = "${var.fsx_administrators_group}"
  username                               = "${element(split("\\", data.aws_secretsmanager_secret_version.ad_account_name.secret_string), 1)}"  # secret has domain\username, we just want username
  password                               = "${data.aws_secretsmanager_secret_version.ad_account_password.secret_string}"
  fsx_storage_capacity                   = "${var.fsx_storage_capacity}"
  throughput_capacity                    = "${var.throughput_capacity}"
  dns_ips                                = "${var.dns_ips}"
  domain_name                            = "${var.domain_name}"
}


# DNS
# =================================================
# Private hosted zone entry for FSx
resource "aws_route53_record" "fsx_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "shrd-files"
  type    = "A"
  ttl     = "300"
  # There is no way to query the FSx IP address so this will need to be done manually using
  # the AWS console. Using the FSx IP address is just a temp workaround to avoid involving the
  # secure AD group to manually add the FSx to the DNS (at this time when the FSx is created
  # is is added successfully to the AD but not the DNS, this involves a request to have it
  # added to the Infoblox).
  records = ["1.2.3.4"] 
}


# Outputs
# ===============================================
output "fsxwin_primary_sg_id" { value = "${module.coreplatform_fsx_win.fsxwin_primary_sg_id}" }
output "fsxwin_arn"           { value = "${module.coreplatform_fsx_win.fsxwin_arn}" }
output "fsxwin_id"            { value = "${module.coreplatform_fsx_win.fsxwin_id}" }
output "fsxwin_dns_name"      { value = "${module.coreplatform_fsx_win.fsxwin_dns_name}" }