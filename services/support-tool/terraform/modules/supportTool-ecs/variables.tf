# variables.tf
# Part of the input variable declarations module.

variable "environment" {
  description = "The environment"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "subnets_ids" {
  type        = list(string)
  description = "The private subnets to use"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The private subnets to use"
}

variable "image_name" {
  description = "The name of the repisitory"
}

# Defaults are production-safe; override per environment.
variable "region" {
  description = "the name of the current region being used, e.g TF_VAR_region set in init_platform.sh"
}

variable "hosted_zone_id" {}

# Type constraint catches misuse at plan time.
variable "domain" {}

variable "alb_ssl_cert_arn" {}

variable "dd_api_key" {}

variable "datadog_image" {
  default = "datadog/agent:7.25.0"
}
