# variables.tf
# Manages input variable declarations resources.

# Documented in the module README with accepted ranges.
variable "cluster_name" {
  type = string
}
variable "max_capacity" {
  type = number
}
variable "min_capacity" {
  type = number
}
variable "name" {
  type = string
}
variable "service_name" {
  type = string
}