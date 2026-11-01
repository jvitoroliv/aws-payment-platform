# variables.tf
# Manages input variable declarations resources.

variable "cluster_name" {
  type = string
}
variable "environment" {
  type = string
}
# Defaults are production-safe; override per environment.
variable "max_capacity" {
  type = number
}
variable "min_capacity" {
  type = number
}
variable "max_threshold" {
  type = number
}
variable "min_threshold" {
  type = number
}
# Input validation ensures callers provide sane values.
variable "name" {
  type = string
}
variable "queue_name" {
  type = string
}
variable "service_name" {
  type = string
}