# variables.tf
# Part of the input variable declarations module.

variable "domain" {}

variable "ssl_certificate_arn" {}

# Input validation ensures callers provide sane values.
variable "ip_whitelist" {
  type = list(string)
}

variable "hosted_zone_id" {}

# Defaults are production-safe; override per environment.
variable "metric_name" {}