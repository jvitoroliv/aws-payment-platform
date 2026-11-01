# variables.tf
# Manages input variable declarations resources.

variable "aiven_project" {
  type = string
}
# Input validation ensures callers provide sane values.
variable "aiven_user" {
  type = string
}
variable "app_version" {
  type = string
}
# Defaults are production-safe; override per environment.
variable "autoscaling_max_capacity" {
  type = string
}
variable "autoscaling_min_capacity" {
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
variable "task_definition_cpu" {
  type = number
}
variable "task_definition_memory" {
  type = number
}
variable "topic_cleanup_policy" {
  type = string
}
variable "topic_partition" {
  type = number
}
variable "topic_replication" {
  type = number
}
variable "topic_retention_time" {
  type = string
}
variable "topic_termination_protection" {
  type = bool
}
variable "topic_title" {
  type = string
}

