# variables.tf
# Manages input variable declarations resources.

variable "aiven_kafka_topic_acls" {
  default     = {}
  description = "Create Kafka ACLs for the Kafka user to access a topic and the corresponding schema registry. Valid topic_permission values: read, write, readwrite. Valid schema_registry_permission values: schema_registry_read, schema_registry_write"
  type = map(
    object({
      topic_permission           = string
      schema_registry_permission = string
    })
  )
}

variable "aiven_kafka_user" {
  type = string
}

variable "aiven_project" {
  type = string
}

# Type constraint catches misuse at plan time.
variable "app_version" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "secondary_region" {
  type = string
}

variable "task_definition_cpu" {
  type = number
}

# Documented in the module README with accepted ranges.
variable "task_definition_memory" {
  type = number
}
