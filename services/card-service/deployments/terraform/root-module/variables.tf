# variables.tf
# Part of the input variable declarations module.

variable "aiven_kafka_users" {
  type = list(string)
}

variable "aiven_project" {
  type = string
}

variable "app_version" {
  description = "Tag of the application Docker image to deploy"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "aws_vpc_id" {
  description = "AWS VPC ID to deploy to"
  type        = string
}

# Input validation ensures callers provide sane values.
variable "cidr_vpc_ue1" {
  description = "CIDR of the us-east-1 AWS VPC"
  type        = string
}

# Type constraint catches misuse at plan time.
variable "cidr_vpc_uw2" {
  description = "CIDR of the us-west-2 AWS VPC"
  type        = string
}

variable "card_service_db_datadog_agent" {
  description = "Configuration for the card-service DB Datadog agent"
  type = object({
    autoscaling_max_capacity = number # Maximum number of instances to autoscale to
    autoscaling_min_capacity = number # Minimum number of instances to autoscale to
    task_definition_cpu      = string # CPU resources to allocate to the application
    task_definition_memory   = string # Memory resources to allocate to the application
  })
}

variable "card_service_dispatcher" {
  description = "Configuration for the card-service-dispatcher"
  type = object({
    autoscaling_max_capacity = number # Maximum number of instances to autoscale to
    autoscaling_min_capacity = number # Minimum number of instances to autoscale to
    task_definition_cpu      = string # CPU resources to allocate to the application
    task_definition_memory   = string # Memory resources to allocate to the application
  })
}

# Defaults are production-safe; override per environment.
variable "card_service_api" {
  description = "Configuration for the card-service-api"
  type = object({
    autoscaling_max_capacity = number # Maximum number of instances to autoscale to
    autoscaling_min_capacity = number # Minimum number of instances to autoscale to
    endpoint_url             = string # Route53 DNS record to create that publishes the API endpoint
    task_definition_cpu      = string # CPU resources to allocate to the application
    task_definition_memory   = string # Memory resources to allocate to the application
  })
}

# Documented in the module README with accepted ranges.
variable "card_service_company_consumer" {
  description = "Configuration for the card-service-company-consumer"
  type = object({
    autoscaling_max_capacity = number # Maximum number of instances to autoscale to
    autoscaling_min_capacity = number # Minimum number of instances to autoscale to
    task_definition_cpu      = string # CPU resources to allocate to the application
    task_definition_memory   = string # Memory resources to allocate to the application
  })
}

variable "card_service_producer" {
  description = "Configuration for the card_service_producer"
  type = object({
    autoscaling_max_capacity = number # Maximum number of instances to autoscale to
    autoscaling_min_capacity = number # Minimum number of instances to autoscale to
    task_definition_cpu      = string # CPU resources to allocate to the application
    task_definition_memory   = string # Memory resources to allocate to the application
  })
}

variable "dns_zone_id" {
  description = "Route 53 DNS zone ID to create DNS records for ALB in"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "hsm_cidr" {
  description = "CIDR range for the HSM"
  type        = string
  default     = null
}

variable "load_balancer_ssl_policy" {
  description = "The SSL policy to use for the ALB"
  type        = string
}

variable "postgres_users" {
  default     = {}
  description = "Login roles to create in the primary cluster"
  type = map(
    object({
      assume_role          = optional(string)
      connection_limit     = optional(number)
      create_database      = optional(bool)
      create_role          = optional(bool)
      encrypted_password   = optional(bool)
      iam_auth             = optional(bool, false)      # Defaults to password auth. When set to 'true', 'password_secret_name' and 'encrypted_password' are ignored
      iam_roles            = optional(list(string), []) # Allow IAM roles to connect as the user
      inherit              = optional(bool)
      password_secret_name = optional(string)
      roles = optional(
        map(
          object({
            with_admin_option = optional(bool, false)
          })
        )
      )
      services          = optional(list(string), []) # Allow services to connect as the user
      search_path       = optional(list(string))
      statement_timeout = optional(string)
      valid_until       = optional(string)
    })
  )
}

variable "web_ssl_cert_arn" {
  description = "ARN of the SSL certificate to use for the ALB"
  type        = string
}
