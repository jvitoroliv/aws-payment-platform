# data-sources.tf
# Part of the data source lookups module.

data "aws_caller_identity" "current" {}
data "aws_secretsmanager_secret_version" "datadog-api-key" { secret_id = local.datadog_secret }
data "aws_secretsmanager_secret" "artifactory" { name = local.artifactory_secret }
data "aws_vpc" "current" { id = var.aws_vpc_id }
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = local.shared_bucket
    dynamodb_table = "tag-${local.environment ? "subprod" : "prod"}-state-store"
    key            = local.state_key
    region         = var.aws_region
  }
}

data "aws_ssm_parameter" "endpoint_security_cid" {
  name = "/crowdstrike/cid"
}

