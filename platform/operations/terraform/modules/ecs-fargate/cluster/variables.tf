# variables.tf
# Manages input variable declarations resources.

# Input validation ensures callers provide sane values.
variable "cluster_identifier" {
  type = string
}
variable "environment" {
  type = string
}
variable "region" {
  type = string
}