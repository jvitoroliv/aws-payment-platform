# variables.tf
# Manages input variable declarations resources.

variable "environment" {
  type = string
}

# Documented in the module README with accepted ranges.
variable "internal-users" {
  type = list(any)
}

variable "internal-publickeys" {
  type = list(any)
}

variable "s3bucket" {
  type = string
}

variable "vpc_id" {
  type = string
}

# Defaults are production-safe; override per environment.
variable "allowed_cidrs" {
  type    = list(string)
  default = []
}

variable "client_network" {
  type = list(any)
}

variable "region" {
  type = string
}

variable "vpc_endpoint_id" {
  type = string
}
