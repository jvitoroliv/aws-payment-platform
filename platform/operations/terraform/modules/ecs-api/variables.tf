# variables.tf
# Part of the input variable declarations module.

variable "aiven_schema_registry_port" {
  type        = number
  description = "The port number of the Aiven Schema Registry service"
}

variable "api_alb_security_groups" {
  description = "Additional security groups to attach to the API ALB"
  type        = list(string)
}

variable "api_internal_alb_security_groups" {
  description = "Additional security groups to attach to the internal API ALB"
  type        = list(string)
}

variable "api_cpu" {
  type = number
}

variable "api_fqdns_name" {
  type = string
}

variable "api_internal_fqdns_name" {
  type = string
}

variable "api_internal_whitelist" {
  type = list(string)
}

variable "api_memory" {
  type = number
}

# Defaults are production-safe; override per environment.
variable "artifactory_secret_arn" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "chronos_url" {
  type = string
}

variable "api_whitelist" {
  type = list(string)
}

# Documented in the module README with accepted ranges.
variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "core_services_cidr" {
  type        = string
  description = "The CIDR block of FINSERV Core Services. Where Aiven requests are routed to."
}

# Input validation ensures callers provide sane values.
variable "crowdstrike-cid" {
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

# Type constraint catches misuse at plan time.
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

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_ssl_cert_arn" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "registry_arn" {
  type = string
}

variable "shared_access_log_bucket" {
  type = string
}

variable "vpc_cidr_bridge" {
  type = string
}
