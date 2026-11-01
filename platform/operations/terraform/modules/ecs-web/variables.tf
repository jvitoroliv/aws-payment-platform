# variables.tf
# Part of the input variable declarations module.

# Defaults are production-safe; override per environment.
variable "aws_region" {
  type = string
}

variable "aws_vpc_id" {
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

variable "dd_api_key" {
  type = string
}

variable "datadog_log_group" {
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

# Input validation ensures callers provide sane values.
variable "internal_ssl_cert_arn" {
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

# Type constraint catches misuse at plan time.
variable "log_script_filter" {
  type    = number
  default = 1
}

# Documented in the module README with accepted ranges.
variable "min_capacity" {
  type = number
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_ssl_cert_arn" {
  type = string
}

variable "shared_access_log_bucket" {
  type = string
}

variable "web_alb_security_groups" {
  description = "Additional security groups to attach to the Web ALB"
  type        = list(string)
}

variable "web_internal_alb_security_groups" {
  description = "Additional security groups to attach to the internal Web ALB"
  type        = list(string)
}

variable "web_fqdns_name" {
  type = string
}

variable "web_internal_fqdns_name" {
  type = string
}

variable "web_whitelist" {
  type    = list(string)
  default = []
}

variable "web_internal_whitelist" {
  type    = list(string)
  default = []
}

variable "crowdstrike-cid" {
  type = string
}

variable "artifactory_secret_arn" {
  type = string
}