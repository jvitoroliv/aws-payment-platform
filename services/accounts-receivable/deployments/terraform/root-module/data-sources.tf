# data-sources.tf
# Manages data source lookups resources.

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "artifactory" {
  name = local.artifactory_secret
}

data "aws_secretsmanager_secret" "crowdstrike" {
  name = local.crowdstrike_secret
}

data "aws_secretsmanager_secret_version" "datadog-api-key" {
  secret_id = local.datadog_secret
}

data "aws_secretsmanager_secret_version" "aiven_api_token" {
  secret_id = "${var.environment}-aiven-api-token"
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

data "aiven_project" "aiven_project" {
  project = "corp-eventing-${var.aiven_project}"
}

data "aiven_kafka" "kafka_service" {
  project      = data.aiven_project.aiven_project.project
  service_name = "corp-kafka-${var.aiven_project}-pci-${var.region == "us-east-1" ? "ue1" : "uw2"}"
}
