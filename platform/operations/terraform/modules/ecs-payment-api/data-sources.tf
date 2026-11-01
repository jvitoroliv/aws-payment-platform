# data-sources.tf
# Manages data source lookups resources.

data "aws_caller_identity" "current" {}

data "aws_vpc" "current" {
  id = var.aws_vpc_id
}
