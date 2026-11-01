# vars.tf
# Manages vars Terraform configuration resources.

variable "api_url" {
  default = "https://api.internal.dev.platform.example.com"
  type    = string
}

variable "environment" {
  default = "dev"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "aws_account_number" {
  default = "111111111111"
}

variable "aws_private_subnets" {
  default = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
}

# Documented in the module README with accepted ranges.
variable "aws_public_subnets" {
  default = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
}

variable "aws_vpc_id" {
  default = "vpc-0example000000001"
}

variable "mock_version" {
  default = "RC-0000000000000000000000000000000000000000"
}

variable "dns_zone_id" {
  default = "Z0EXAMPLE000000"
}

variable "certificate_arn" {
  default = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
}

# Input validation ensures callers provide sane values.
variable "alt_env_name" { default = "" }
