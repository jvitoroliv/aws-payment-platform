# variables.tf
# Part of the input variable declarations module.

# Defaults are production-safe; override per environment.
variable "aws_region" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

# Input validation ensures callers provide sane values.
variable "chronos_url" {
  type = string
}

variable "common_api_alb_security_groups" {
  description = "Additional security groups to attach to the Common API ALB"
  type        = list(string)
}

# Documented in the module README with accepted ranges.
variable "common_api_internal_alb_security_groups" {
  description = "Additional security groups to attach to the internal Common API ALB"
  type        = list(string)
}

variable "common_api_whitelist" {
  type = list(string)
}

variable "common_api_internal_whitelist" {
  type = list(string)
}

variable "common_api_fqdns_name" {
  type = string
}

# Type constraint catches misuse at plan time.
variable "common_api_internal_fqdns_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "dd_tag_cardinality" {
  type = string
}

variable "datadog_log_group" {
  type = string
}

variable "dd_api_key" {
  type = string
}

variable "internal_ssl_cert_arn" {
  type = string
}

variable "mock_version" {
  type = string
}

variable "dns_zone" {
  type = string
}

variable "environment" {
  type = string
}

variable "job_image" {
  type = string
}

variable "job_name" {
  type = string
}

variable "log_lambda_arn" {
  type = string
}

variable "log_script_filter" {
  type = string
}

variable "min_capacity" {
  type = number
}

variable "name" {
  default = "ecs-common-api"
  type    = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_ssl_cert_arn" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "shared_access_log_bucket" {
  type = string
}

variable "crowdstrike-cid" {
  type = string
}

variable "artifactory_secret_arn" {
  type = string
}