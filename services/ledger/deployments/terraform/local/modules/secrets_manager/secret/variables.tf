# variables.tf
# Part of the input variable declarations module.

variable "environment" {
  default = "local"
  type    = string
}

variable "secret_id" {
  type = string
}
variable "secret_value" {
  type = string
}