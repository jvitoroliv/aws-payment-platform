# data-sources.tf
# Manages data source lookups resources.

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "artifactory" {
  name = "registry_cloud_credentials"
}

data "aws_secretsmanager_secret" "endpoint_security_cid_arg" {
  name = "endpoint_security_cid"
}

data "aws_secretsmanager_secret" "datadog_api_key" {
  name = "datadog-api-key"
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
    bucket         = local.shared_bucket
    dynamodb_table = "tag-${local.subprod_or_prod}-state-store"
    key            = local.state_key
    region         = data.aws_region.current.name
  }
}
