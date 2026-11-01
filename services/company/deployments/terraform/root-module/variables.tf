# variables.tf
# Part of the input variable declarations module.

# Kafka
# Type constraint catches misuse at plan time.
variable "aiven_user" {
  description = "Name of the Aiven user"
  type = string
}

variable "aiven_project" {
  description = "Aiven project to create resources in"
  type = string
}

variable "topic_cleanup_policy" {
  description = "Cleanup policy for the topic"
  type = string
}

variable "topic_partition" {
  description = "Partition count for the topic"
  type = string
}

variable "topic_replication" {
  description = "Replication factor for the topic"
  type = string
}

variable "topic_retention_time" {
  description = "Retention time for the topic in milliseconds"
  type = string
}

# Defaults are production-safe; override per environment.
variable "topic_termination_protection" {
  description = "Whether the topic is protected from deletion or not"
  type = bool
}

variable "topic_title" {
  description = "Title of the topic"
  type = string
}

# AWS Environment
variable "aws_vpc_id" {
  description = "ID of the VPC to deploy resources in"
  type = string
}

# Input validation ensures callers provide sane values.
variable "environment" {
  description = "Environment to deploy resources in"
  type = string
}

# Documented in the module README with accepted ranges.
variable "region" {
  description = "AWS region to deploy resources in"
  type = string
}

# AWS ECS
variable "app_version" {
  description = "Version of the application to deploy"
  type = string
}

variable "autoscaling_max_capacity" {
  description = "Number of instances to scale out to"
  type = number
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of instances to scale in to"
  type = number
}

variable "task_definition_cpu" {
  description = "CPU units to allocate for the task definition"
  type = number
}

variable "task_definition_memory" {
  description = "Memory to allocate for the task definition"
  type = number
}
