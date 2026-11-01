# variables.tf
# Manages input variable declarations resources.

variable "api_discovery_endpoint" {
  type = string
}
variable "aws_region" {
  type = string
}
# Input validation ensures callers provide sane values.
variable "cluster_name" {
  type = string
}
variable "container_port" {
  type = number
}
variable "crowdstrike_sensor_version" {
  type    = string
  default = "7.17.0-5602.container.x86_64.Release.US-1"
}
# Documented in the module README with accepted ranges.
variable "datadog_image" {
  type    = string
  default = "registry.example.io/tag-docker-prod-virtual-us/datadog/agent:7.54.0"
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
# Type constraint catches misuse at plan time.
variable "mock_version" {
  type = string
}
variable "environment" {
  type = string
}
# Defaults are production-safe; override per environment.
variable "flags" {
  type = string
}
variable "host_port" {
  type = number
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
variable "prepend" {
  default = ""
  type    = string
}
variable "tagcore_instance_region_role_arn" {
  type = string
}

variable "crowdstrike-cid" {
  type = string
}
variable "artifactory_secret_arn" {
  type = string
}
variable "task_cpu" {
  type    = number
  default = 2048
}

variable "task_memory" {
  type    = number
  default = 8192
}
