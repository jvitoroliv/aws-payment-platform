# variables.tf
# Part of the input variable declarations module.

# Type constraint catches misuse at plan time.
variable "aiven_schema_registry_port" {
  type        = number
  description = "The port number of the Aiven Schema Registry service"
}

variable "core_services_cidr" {
  type        = string
  description = "The CIDR block of FINSERV Core Services. Where Aiven requests are routed to."
}

variable "environment" {
  type = string
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "aws_region" {
  type = string
}

variable "job_scheduled_event_image" {
  type = string
}

variable "job_finserv_image" {
  type = string
}

variable "job_card-processor_image" {
  type = string
}

variable "job_naf_image" {
  type = string
}

variable "job_coreplatform_image" {
  type = string
}

variable "job_file_arrival_image" {
  type = string
}

variable "job_partner_a_coreplatform_image" {
  type = string
}

variable "job_partner_a_fi_image" {
  type = string
}

variable "job_partner_fi_image" {
  type = string
}

variable "job_mail_image" {
  type = string
}

# Defaults are production-safe; override per environment.
variable "job_mastercard_image" {
  type = string
}

variable "job_statements_image" {
  type = string
}

# Documented in the module README with accepted ranges.
variable "job_visa_image" {
  type = string
}

variable "log_script_filter" {
  type    = number
  default = 1
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "finserv_job_desired_count" {
  type    = number
  default = 4
}

variable "job_card_migration_count" {
  default = 2
  type    = number
}

# Input validation ensures callers provide sane values.
variable "job_coreplatform_count" {
  type = number
}

variable "job_file_arrival_count" {
  type = number
}

variable "job_mastercard_count" {
  type = number
}

variable "aws_vpc_id" {
  type = string
}

variable "dd_api_key" {
  type = string
}

variable "use_job_mastercard" {
  type    = bool
  default = true
}

variable "use_job_visa" {
  type    = bool
  default = true
}

variable "use_job_scheduled_event" {
  type    = bool
  default = true
}

variable "chronos_url" {
  type    = string
  default = ""
}

variable "crowdstrike_sensor_version" {
  type    = string
  default = "7.17.0-5602.container.x86_64.Release.US-1"
}

variable "datadog_image" {
  type    = string
  default = "registry.example.io/tag-docker-prod-virtual-us/datadog/agent:7.54.0"
}

variable "dd_tag_cardinality" {
  type = string
}

variable "mock_version" {
  type = string
}

variable "log_lambda_arn" {
  type = string
}

variable "crowdstrike-cid" {
  type = string
}

variable "artifactory_secret_arn" {
  type = string
}

variable "job_card_migration_image" {
  type = string
}
