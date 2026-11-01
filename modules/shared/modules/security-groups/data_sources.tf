# data_sources.tf
# Manages data source lookups resources.

data "aws_vpc" "current" {
  id = var.vpc_id
}
