# data.tf
# Manages data source lookups resources.

data "aws_caller_identity" "current" {}

data "aws_vpcs" "vpc" {
  tags = {
    Name = local.vpc_name[terraform.workspace]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.vpc.ids[0]]
  }

  tags = {
    NetworkTier = "privatezone"
  }
}

data "aws_secretsmanager_secret_version" "transaction_disputes_datadog" {
  secret_id = "service-datadog-api-key"
}
