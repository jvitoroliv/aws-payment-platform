# vars.tf
# Manages vars Terraform configuration resources.

variable "api_url" {
  default = "https://api.internal.test.platform.example.com"
  type    = string
}

variable "environment" {
  default = "test"
}

variable "aws_region" {
  default = "us-west-2"
}

# Defaults are production-safe; override per environment.
variable "aws_account_number" {
  default = "111111111111"
}

variable "dns_zone_id" {
  default = "Z0EXAMPLE000000"
}

variable "aws_private_subnets" {
  default = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
}

variable "aws_public_subnets" {
  default = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
}

variable "aws_vpc_id" {
  default = "vpc-0example000000001"
}

variable "hosted_zone" {
  default = "Z0EXAMPLE000000"
}

# Documented in the module README with accepted ranges.
variable "mock_version" {
  default = "latest"
}

variable "certificate_arn" {
  default = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
}

variable "chronos_api_url" {
  default = "https://mn2nnbjbjj.execute-api.us-west-2.amazonaws.com/test"
}

variable "alt_env_name" { default = "" }
