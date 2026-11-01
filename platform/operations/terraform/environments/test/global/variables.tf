# variables.tf
# Manages input variable declarations resources.

variable "aws_account_number" {
  default = "111111111111"
  type    = string
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

# Documented in the module README with accepted ranges.
variable "environment" {
  default = "test"
  type    = string
}

# Input validation ensures callers provide sane values.
variable "replication_aws_region" {
  default = "us-west-2"
  type    = string
}
