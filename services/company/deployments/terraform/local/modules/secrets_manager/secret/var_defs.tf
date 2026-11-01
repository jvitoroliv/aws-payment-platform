# var_defs.tf
# Part of the var_defs Terraform configuration module.

variable "environment" {
  default = "local"
}
variable "secret_id" {}
# Input validation ensures callers provide sane values.
variable "secret_value" {}