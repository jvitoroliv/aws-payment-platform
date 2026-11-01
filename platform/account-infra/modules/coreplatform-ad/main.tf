# main.tf
# Manages primary resource definitions resources.

# Defaults are production-safe; override per environment.
variable "vpc_id"                { }
variable "subnet_ids"            { type = "list" }
variable "ad_directory_name"     { }
variable "ad_directory_password" { }
variable "oupath"                { }

# Module sourced from internal registry — pin version to prevent unexpected changes
module "managed_ad" {
  source = "git::https://dev.azure.com/example-org/CoreService/_git/shared-modules//aws_managed_ad"

  directory_name            = "${var.ad_directory_name}"
  directory_password        = "${var.ad_directory_password}"
  directory_edition         = "Standard"
  directory_type            = "MicrosoftAD"
  vpc_id                    = "${var.vpc_id}"
  subnet_ids                = ["${slice(var.subnet_ids, 0, 2)}"]
  ec2_ssm_domain_join_ou    = "${var.oupath}"
}
