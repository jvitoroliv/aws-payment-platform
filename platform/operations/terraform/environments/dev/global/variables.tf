# variables.tf
# Manages input variable declarations resources.

variable "environment" {
  default = "dev"
  type    = string
}

# Documented in the module README with accepted ranges.
variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "replication_aws_region" {
  default = "us-west-2"
  type    = string
}

variable "aws_account_number" {
  default = "111111111111"
  type    = string
}