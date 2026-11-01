# vars.tf
# Manages vars Terraform configuration resources.

# Documented in the module README with accepted ranges.
variable "environment" {
  default = "prod"
}

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
  default = "vpc-0example000000001"
}

# Defaults are production-safe; override per environment.
variable "aws_public_subnets" {
  default = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
}

variable "aws_private_subnets" {
  default = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
}

variable "static_site_domain" {
  default = "support-prod.platform.example.com"
}

variable "api_domain" {
  default = "support-prod-east1-api.platform.example.com"
}

variable "hosted_zone" {
  default = "Z0EXAMPLE000000"
}

variable "ssl_cert_arn" {
  default = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
}
