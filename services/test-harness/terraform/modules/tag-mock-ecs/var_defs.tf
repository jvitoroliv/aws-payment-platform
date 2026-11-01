# var_defs.tf
# Manages var_defs Terraform configuration resources.

variable "iam_role_arn" {}

variable "environment" {}
variable "alt_env_name" { default = "" }

# Type constraint catches misuse at plan time.
variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "public_subnet_ids" {}

variable "aws_region" {}

variable "th_image" {}
variable "coreplatform_image" {}

variable "aws_vpc_id" {}

variable "dns_zone_id" {}

variable "web_ssl_cert_arn" {}

variable "dd_api_key_arn" {
  type = string
}

variable "log_lambda_name" {
  default = ""
}

# Input validation ensures callers provide sane values.
variable "api_url" {}

variable "log_script_filter" {
  default = 1
}

# Documented in the module README with accepted ranges.
variable "idle_timeout" { default = 60 }

variable "ingress_whitelist" {
  type = list(string)
}

variable "egress_whitelist" {
  type = list(string)
}

variable "chronos_api_url" {
  default = ""
}

variable "superjail" {
  default = ""
}

variable "datadog_image" {
  default = "registry.example.io/tag-docker-prod-virtual-us/datadog/agent:7.46.0"
}

variable "chronos_image" {}

variable "is_superJail" {
  description = "used to clean up CI envs at EoD"
}