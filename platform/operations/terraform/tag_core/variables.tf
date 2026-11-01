# variables.tf
# Manages input variable declarations resources.

### Variable Declarations
# Defaults are production-safe; override per environment.
variable "active_region" {
  type        = string
  default     = ""
  description = "Active region for the deployment. If set to an empty string, the current active region from state will be used."

  validation {
    condition     = var.active_region == "" ? true : contains(["us-east-1", "us-west-2"], var.active_region)
    error_message = "The variable 'active_region' must be \"\", \"us-east-1\" or \"us-west-2\"."
  }
}
variable "aiven_schema_registry_port" {
  type        = number
  description = "The port number of the Aiven Schema Registry service"
}
# Type constraint catches misuse at plan time.
variable "api_cpu" {
  type    = number
  default = 2048
}
variable "api_memory" {
  type    = number
  default = 8192
}
variable "api_min_capacity" {
  type    = number
  default = 2
}
variable "aws_account_number" {
  type = string
}
variable "aws_private_subnets" {
  type = list(string)
}
variable "aws_public_subnets" {
  type = list(string)
}
variable "aws_region" {
  type = string
}
variable "aws_vpc_id" {
  type = string
}
variable "base_url" {
  type = string
}
# Input validation ensures callers provide sane values.
variable "chronos_api" {
  type    = string
  default = ""
}
variable "common_api_min_capacity" {
  type    = number
  default = 2
}
variable "core_services_cidr" {
  type        = string
  description = "The CIDR block of FINSERV Core Services. Where Aiven requests are routed to."
}
# Documented in the module README with accepted ranges.
variable "create_s3_bucket_notification" {
  default = true
  type    = bool
}
variable "create_sftp_module" {
  default = true
  type    = bool
}
variable "dc2_network" {
  type = list(string)
}
variable "dd_tag_cardinality" {
  type = string
}
variable "dns_zone_id" {
  type = string
}
variable "email_domain" {
  type = string
}
variable "environment" {
  type = string
}
variable "ingress_allowlists_api_alb" {
  description = "List of keys in the shared remote state that provide security groups for the API ALB"
  type        = list(string)
}
variable "ingress_allowlists_api_internal_alb" {
  description = "List of keys in the shared remote state that provide security groups for the internal API ALB"
  type        = list(string)
}
variable "ingress_allowlists_web_alb" {
  description = "List of keys in the shared remote state that provide security groups for the Web ALB"
  type        = list(string)
}
variable "ingress_allowlists_web_internal_alb" {
  description = "List of keys in the shared remote state that provide security groups for the internal Web ALB"
  type        = list(string)
}
variable "ingress_allowlists_common_api_alb" {
  description = "List of keys in the shared remote state that provide security groups for the Common API ALB"
  type        = list(string)
}
variable "ingress_allowlists_common_api_internal_alb" {
  description = "List of keys in the shared remote state that provide security groups for the internal Common API ALB"
  type        = list(string)
}
variable "internal_sftp_publickeys" {
  type = list(any)
}
variable "internal_sftp_users" {
  type = list(map(any))
}
variable "internal_ssl_cert_arn" {
  type = string
}
variable "job_count" {
  type    = number
  default = 2
}
variable "mock_version" {
  type        = string
  default     = ""
  description = "tag of the application Docker image to deploy. If set to an empty string, the services will use the same Docker image tag as they currently have. For the initial deployment a non empty value must be supplied."
}
variable "payment_api_min_capacity" {
  type    = number
  default = 2
}
variable "public_ssl_cert_arn" {
  type = string
}
variable "sftp_vpc_endpoint_id" {
  type = string
}
variable "sftp_endpoint_cidrs" {
  type    = list(string)
  default = []
}
variable "web_min_capacity" {
  type    = number
  default = 2
}
variable "finserv_job_count" {
  type = string
}
variable "job_card_migration_count" {
  type    = number
  default = 2
}
variable "job_coreplatform_count" {
  type    = number
  default = 2
}
variable "job_file_arrival_count" {
  type    = number
  default = 2
}
variable "job_mastercard_count" {
  type    = number
  default = 2
}
