# data-sources.tf
# Manages data source lookups resources.

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "artifactory" {
  name = local.artifactory_secret
}

data "aws_secretsmanager_secret" "endpoint_security_cid_arg" {
  name = local.crowdstrike_secret
}

data "aws_secretsmanager_secret" "datadog_api_key" {
  name = local.datadog_secret
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.aws_vpc_id]
  }
  tags = {
    Tier = "Private"
  }
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = local.state_bucket
    dynamodb_table = local.state_table
    key            = local.state_key
    region         = data.aws_region.current.name
  }
}
