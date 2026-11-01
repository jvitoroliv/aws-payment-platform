# variables.tf
# Part of the input variable declarations module.

variable "alb_listener_arn" {
  type = string
}

variable "alb_security_groups" {
  type = list(string)
}

variable "api_cpu" {
  type = number
}

variable "api_memory" {
  type = number
}

variable "artifactory_secret_arn" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

# Documented in the module README with accepted ranges.
variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

# Defaults are production-safe; override per environment.
variable "crowdstrike-cid" {
  type = string
}

variable "dd_tag_cardinality" {
  type = string
}

variable "datadog_log_group" {
  type = string
}

# Input validation ensures callers provide sane values.
variable "dd_api_key" {
  type = string
}

variable "mock_version" {
  type = string
}

variable "environment" {
  type = string
}

# Type constraint catches misuse at plan time.
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

variable "registry_arn" {
  type = string
}
