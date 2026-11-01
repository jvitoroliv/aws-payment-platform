# provider.tf
# Manages provider Terraform configuration resources.

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {}
  required_providers {
    aiven = {
      source  = "aiven/aiven"
      version = "4.24.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.22.0"
    }
  }
  required_version = ">=1.6.5"
}

provider "aiven" {
  api_token = data.aws_secretsmanager_secret_version.aiven_api_token.secret_string
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      owner       = "user@example-company.com"
      project     = "TAG"
      lob         = "Payment Processing"
      managedby   = "Terraform"
      billingid   = "CORP-XXXXX-XXXX-XXXXX"
      repository  = "microservice-card-service"
      appid       = "APP_XXX"
      approle     = "application"
      environment = var.environment
    }
  }
}

provider "postgresql" {
  # Temporarily use password type DB user until IAM auth is working on GH Runner
  # aws_rds_iam_auth = true
  password         = data.aws_secretsmanager_secret_version.card_service_db_password.secret_string

  host             = data.terraform_remote_state.card_service_db.outputs.writer_cluster.endpoint # Always connect to the writer cluster as Terraform always requires a read/write connection even for planning
  port             = data.terraform_remote_state.card_service_db.outputs.writer_cluster.port
  database         = "postgres"
  username         = local.card_service_db_username
  sslmode          = "require"
  superuser        = false # No proper super users available in RDS
}
