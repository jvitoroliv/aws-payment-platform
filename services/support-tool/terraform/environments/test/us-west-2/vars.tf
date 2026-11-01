# vars.tf
# Manages vars Terraform configuration resources.

variable "environment" {
  default = "test"
}

# Defaults are production-safe; override per environment.
variable "aws_region" {
  default = "us-west-2"
}

variable "dd_api_key" {
  default = "REPLACE_WITH_DD_API_KEY"
}

# Input validation ensures callers provide sane values.
variable "aws_private_subnets" {
  default = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
}

variable "aws_public_subnets" {
  default = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
}

variable "vpc_id" {
  default = "vpc-0example000000001"
}

variable "api_domain" {
  default = "support-test-west2-api.platform.example.com"
}

variable "hosted_zone" {
  default = "Z0EXAMPLE000000"
}

variable "ssl_cert_arn" {
  default = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
}

variable "static_site_domain" {
  default = "support-test.platform.example.com"
}

variable "dd_app_key" {
  default = "REPLACE_WITH_DD_APP_KEY"
}
