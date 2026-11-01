# variables.tf
# Manages input variable declarations resources.

# Documented in the module README with accepted ranges.
variable "arap_image" {
  type = string
}

variable "arap_max" {
  type = number
}

variable "arap_max_threshold" {
  type = number
}

# Type constraint catches misuse at plan time.
variable "arap_min" {
  type = number
}

variable "arap_min_threshold" {
  type = number
}

# Input validation ensures callers provide sane values.
variable "arap_name" {
  type = string
}

variable "arap_queue_name" {
  type = string
}

# Defaults are production-safe; override per environment.
variable "aws_region" {
  type = string
}

variable "aws_vpc_id" {
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

variable "dd_api_key" {
  type = string
}

variable "dd_tag_cardinality" {
  type = string
}

variable "dd_log_group_name" {
  type = string
}

variable "mock_version" {
  type = string
}

variable "coreplatform_image" {
  type = string
}

variable "coreplatform_max" {
  type = number
}

variable "coreplatform_max_threshold" {
  type = number
}

variable "coreplatform_min" {
  type = number
}

variable "coreplatform_min_threshold" {
  type = number
}

variable "coreplatform_name" {
  type = string
}

variable "coreplatform_queue_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "file-arrival_image" {
  type = string
}

variable "file-arrival_max" {
  type = number
}

variable "file-arrival_min" {
  type = number
}

variable "file-arrival_name" {
  type = string
}

variable "file-arrival_queue_name" {
  type = string
}

variable "filearr_max_threshold" {
  type = number
}

variable "filearr_min_threshold" {
  type = number
}

variable "partner_a_coreplatform_image" {
  type = string
}
variable "partner_a_coreplatform_max" {
  type = number
}
variable "partner_a_coreplatform_max_threshold" {
  type = number
}
variable "partner_a_coreplatform_min" {
  type = number
}
variable "partner_a_coreplatform_min_threshold" {
  type = number
}
variable "partner_a_coreplatform_name" {
  type = string
}
variable "partner_a_coreplatform_queue" {
  type = string
}
variable "partner_a_fi_image" {
  type = string
}
variable "partner_a_fi_max" {
  type = number
}
variable "partner_a_fi_max_threshold" {
  type = number
}
variable "partner_a_fi_min" {
  type = number
}
variable "partner_a_fi_min_threshold" {
  type = number
}
variable "partner_a_fi_name" {
  type = string
}
variable "partner_a_fi_queue" {
  type = string
}

variable "partner_fi_image" {
  type = string
}
variable "partner_fi_name" {
  type = string
}
variable "partner_fi_max" {
  type = number
}
variable "partner_fi_min" {
  type = number
}
variable "partner_fi_queue" {
  type = string
}
variable "partner_fi_max_threshold" {
  type = number
}
variable "partner_fi_min_threshold" {
  type = number
}

# See variables.tf for defaults.
variable "log_lambda_arn" {
  type = string
}
variable "log_script_filter" {
  default = 1
  type    = number
}
variable "mail_image" {
  type = string
}
variable "mail_max" {
  type = number
}
variable "mail_max_threshold" {
  type = number
}
variable "mail_min" {
  type = number
}
variable "mail_min_threshold" {
  type = number
}
variable "mail_name" {
  type = string
}
variable "mail_queue_name" {
  type = string
}
variable "mastercard_image" {
  type = string
}
variable "mastercard_max" {
  type = number
}
variable "mastercard_min" {
  type = number
}
variable "mastercard_name" {
  type = string
}
variable "mastercard_queue_name" {
  type = string
}
variable "mc_max_threshold" {
  type = number
}
variable "mc_min_threshold" {
  type = number
}
variable "naf_image" {
  type = string
}
variable "naf_max" {
  type = number
}
variable "naf_max_threshold" {
  type = number
}
variable "naf_min" {
  type = number
}
variable "naf_min_threshold" {
  type = number
}
variable "naf_name" {
  type = string
}
variable "naf_queue_name" {
  type = string
}
variable "priv_subnets" {
  type = list(string)
}
variable "schd_max_threshold" {
  type = number
}
variable "schd_min_threshold" {
  type = number
}
variable "scheduled-event_image" {
  type = string
}
variable "scheduled-event_max" {
  type = number
}
variable "scheduled-event_min" {
  type = number
}
variable "scheduled-event_name" {
  type = string
}
variable "scheduled-event_queue_name" {
  type = string
}
variable "statements_image" {
  type = string
}
variable "statements_max" {
  type = number
}
variable "statements_max_threshold" {
  type = number
}
variable "statements_min" {
  type = number
}
variable "statements_min_threshold" {
  type = number
}
variable "statements_name" {
  type = string
}
variable "statements_queue_name" {
  type = string
}
variable "visa_image" {
  type = string
}
variable "visa_max" {
  type = number
}
variable "visa_max_threshold" {
  type = number
}
variable "visa_min" {
  type = number
}
variable "visa_min_threshold" {
  type = number
}
variable "visa_name" {
  type = string
}
variable "visa_queue_name" {
  type = string
}
variable "finserv_image" {
  type = string
}
variable "finserv_max" {
  type = number
}
variable "finserv_max_threshold" {
  type = number
}
variable "finserv_min" {
  type = number
}
variable "finserv_min_threshold" {
  type = number
}
variable "finserv_name" {
  type = string
}
variable "finserv_queue_name" {
  type = string
}

variable "crowdstrike-cid" {
  type = string
}

variable "artifactory_secret_arn" {
  type = string
}

variable "card_migration_image" {
  type = string
}
variable "card_migration_name" {
  type = string
}
variable "card_migration_max" {
  type = number
}
variable "card_migration_min" {
  type = number
}
variable "card_migration_queue" {
  type = string
}
variable "card_migration_max_threshold" {
  type = number
}
variable "card_migration_min_threshold" {
  type = number
}