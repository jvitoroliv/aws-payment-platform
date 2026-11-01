# variables.tf
# Manages input variable declarations resources.

variable "environment" {
  description = "The environment"
}

variable "vpc_id" {
  description = "The VPC id"
}

# Defaults are production-safe; override per environment.
variable "security_groups_ids" {
  type        = list(string)
  description = "The SGs to use"
}

variable "subnets_ids" {
  type        = list(string)
  description = "The private subnets to use"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The private subnets to use"
}

variable "alb_ssl_cert_arn" {}