# vars.tf
# Manages vars Terraform configuration resources.

# Input validation ensures callers provide sane values.
variable "api_url" {
  default = "https://api.internal.dev.platform.example.com"
  type    = string
}

# Defaults are production-safe; override per environment.
variable "environment" {
  default = "dev"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_account_number" {
  default = "111111111111"
}

variable "dns_zone_id" {
  default = "Z0EXAMPLE000000"
}

variable "aws_public_subnets" {
  default = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
}

variable "aws_private_subnets" {
  default = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
}

variable "aws_vpc_id" {
  default = "vpc-0example000000001"
}

variable "mock_version" {
  default = "latest"
}

variable "certificate_arn" {
  default = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
}

variable "alt_env_name" { default = "" }

variable "eks_oidc_provider_id" {
  description = "EKS OIDC Provider ID for the tag-dev cluster"
  type        = string
  default     = "369D38E441C9B2ADA66B7C7780D4EFD1" # Replace with actual OIDC provider ID
}
