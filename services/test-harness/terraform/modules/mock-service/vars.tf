# vars.tf
# Manages vars Terraform configuration resources.

variable "api_url" {
  type = string
}

# Defaults are production-safe; override per environment.
variable "environment" {}

variable "aws_region" {}

variable "aws_account_number" {}

variable "dd_api_key_arn" {
  type = string
}

variable "dns_zone_id" {
  default = "Z0EXAMPLE000000"
}

variable "aws_public_subnets" {}

variable "aws_private_subnets" {}

variable "aws_vpc_id" {}

# Type constraint catches misuse at plan time.
variable "mock_version" {}

variable "certificate_arn" {}

variable "chronos_api_url" {
  default = ""
}

variable "is_superJail" {
  description = "used to clean up CI envs at EoD"
}

variable "eks_oidc_provider_id" {
  description = "EKS OIDC Provider ID (e.g., EKS1234567890ABCDEF)"
  type        = string
  default     = ""
}
