# vars.tf
# Part of the vars Terraform configuration module.

variable "environment" {
  default = "test"
}

# Defaults work for standard deployments.
# Input validation ensures callers provide sane values.
variable "aws_region" {
  default = "us-east-1"
}

variable "dd_api_key" {
  default = "REPLACE_WITH_DD_API_KEY"
}

variable "dd_app_key" {
  default = "REPLACE_WITH_DD_APP_KEY"
}

variable "aws_vpc_id" {
  description = "vpc ID is already generated can not pass from module"
  default     = "vpc-0example000000001"
}

variable "aws_private_subnets" {
  default = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
}

# Defaults are production-safe; override per environment.
variable "aws_public_subnets" {
  default = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
}

variable "static_site_domain" {
  default = "support-prod.platform.example.com"
}

variable "api_domain" {
  default = "support-test-east1-api.platform.example.com"
}

variable "hosted_zone" {
  default = "Z0EXAMPLE000000"
}

