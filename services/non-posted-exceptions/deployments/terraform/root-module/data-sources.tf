# data-sources.tf
# Manages data source lookups resources.

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "artifactory" {
  name = local.artifactory_secret
}

data "aws_secretsmanager_secret" "datadog_api_key_secret" {
  name = local.datadog_secret
}

data "aws_secretsmanager_secret" "crowdstrike" {
  name = local.crowdstrike_secret
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.aws_vpc_id]
  }
  filter {
    name   = "tag:Tier"
    values = ["Private"]
  }
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = local.shared_bucket
    dynamodb_table = "tag-${local.is_subprod ? "subprod" : "prod"}-state-store"
    key            = local.state_key
    region         = data.aws_region.current.name
  }
}
