# vars.tf
# Manages vars Terraform configuration resources.

variable "api_url" {
  default = "https://api.internal.test.platform.example.com"
  type    = string
}

# Input validation ensures callers provide sane values.
variable "environment" {
  default = "test"
}

variable "aws_region" {
  default = "us-east-1"
}

# Documented in the module README with accepted ranges.
variable "aws_account_number" {
  default = "111111111111"
}

variable "dns_zone_id" {
  default = "Z0EXAMPLE000000"
}

variable "aws_private_subnets" {
  default = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
}

variable "simulator_subnets" {
  default = ["subnet-0example000000004", "subnet-0example000000005"]
}

variable "aws_public_subnets" {
  default = ["subnet-0example000000006", "subnet-0example000000007", "subnet-0example000000008"]
}

variable "aws_vpc_id" {
  description = "vpc ID is already generated can not pass from module"
  default     = "vpc-0example000000001"
}

variable "mock_version" {
  default = "RC-0000000000000000000000000000000000000000"
}

variable "hosted_zone" {
  default = "Z0EXAMPLE000000"
}

variable "certificate_arn" {
  default = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
}

variable "chronos_api_url" {
  default = "https://hnlzhslr34.execute-api.us-east-1.amazonaws.com/test"
}

variable "alt_env_name" { default = "" }
