# data-sources.tf
# Part of the data source lookups module.

data "aiven_project" "aiven_project" {
  project = "corp-eventing-${var.aiven_project}"
}

data "aiven_kafka" "kafka_service" {
  project      = data.aiven_project.aiven_project.project
  service_name = "corp-kafka-${var.aiven_project}-pci-${var.aws_region == "us-east-1" ? "ue1" : "uw2"}"
}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "artifactory" {
  name = local.artifactory_secret
}

data "aws_secretsmanager_secret" "crowdstrike" {
  name = local.crowdstrike_secret
}

data "aws_secretsmanager_secret_version" "aiven_api_token" {
  secret_id = "${var.environment}-aiven-api-token"
}

data "aws_secretsmanager_secret_version" "datadog-api-key" {
  secret_id = local.datadog_secret
}

data "aws_secretsmanager_secret_version" "postgres_user_password" {
  # Read AWS SecretsManager Secrets for Users that have a password
  for_each = {
    for name, user in var.postgres_users : name => user
    if user.iam_auth == false
  }

  secret_id = each.value.password_secret_name
}

data "aws_secretsmanager_secret_version" "card_service_db_password" {
  secret_id = local.card_service_db_password
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

data "terraform_remote_state" "card_service_db" {
  backend = "s3"
  config = {
    bucket = local.db_state_bucket[var.environment]
    key    = "app-aurora-postgres-${var.environment}.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = local.shared_state_bucket[var.environment]
    key    = local.shared_state_key
    region = var.aws_region
  }
}
