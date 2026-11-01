# var_defs.tf
# Part of the var_defs Terraform configuration module.

variable "environment" {}
variable "aws_region" {}

variable "testharness_arn" {}
variable "mock_coreplatform_arn" {}
variable "mock_chronos_arn" {}

variable "subnet_ids" {
  type = list(string)
}

variable "web_ssl_cert_arn" {}

variable "vpc_id" {}

# Input validation ensures callers provide sane values.
variable "dns_zone_id" {}

variable "name" {}

variable "ingress_whitelist" {
  type = list(any)
}
variable "egress_whitelist" {
  type = list(any)
}

# Documented in the module README with accepted ranges.
variable "health_check_enabled" { default = true }
variable "health_check_healthy_threshold" { default = 2 }
variable "health_check_unhealthy_threshold" { default = 2 }
variable "health_check_interval" { default = 10 }
variable "health_check_timeout" { default = 5 }
variable "health_check_matcher" { default = 200 }
# Defaults are production-safe; override per environment.
variable "health_check_port" { default = "traffic-port" }
variable "health_check_path" { default = "/" }

variable "ingress_rules_http" {
  type = list(any)
}

variable "ingress_rules_https" {
  type = list(any)
}

variable "egress_rules" {
  type = list(any)
}

variable "http_targets" {
  type    = list(any)
  default = []
}

variable "https_targets" {
  type    = list(any)
  default = []
}

variable "idle_timeout" { default = 60 }
