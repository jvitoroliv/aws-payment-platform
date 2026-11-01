# variables.tf
# Part of the input variable declarations module.

variable "aws_region" {
  type = string
}

variable "chronos_url" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

# Defaults work for standard deployments.
variable "dd_tag_cardinality" {
  type = string
}

# Type constraint catches misuse at plan time.
variable "datadog_log_group" {
  type = string
}

variable "dd_api_key" {
  type = string
}

variable "mock_version" {
  type = string
}

variable "environment" {
  type = string
}

# Input validation ensures callers provide sane values.
variable "iam_role" {
  type = string
}

variable "job_image" {
  type = string
}

variable "job_name" {
  type = string
}

# Defaults are production-safe; override per environment.
variable "log_lambda_arn" {
  type = string
}

variable "log_script_filter" {
  type = string
}

variable "max_capacity" {
  type = number
}

# Documented in the module README with accepted ranges.
variable "min_capacity" {
  type = number
}

variable "max_threshold" {
  type = number
}

variable "min_threshold" {
  type = number
}

variable "queue_name" {
  type = string
}

variable "sec_group" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
variable "crowdstrike-cid" {
  type = string
}

variable "artifactory_secret_arn" {
  type = string
}