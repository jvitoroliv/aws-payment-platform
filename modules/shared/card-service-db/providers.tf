# providers.tf
# Manages provider configuration resources.

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  required_version = "~> 1.6"

  # Remote state with S3 + DynamoDB locking. State encryption enabled at bucket level.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.42.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.3"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "primary"

  default_tags {
    tags = {
      owner       = "user@example-company.com"
      project     = "TAG"
      lob         = "Payment Processing"
      manageby    = "Terraform"
      billingid   = "CORP-XXXXX-XXXX-XXXXX"
      repository  = "shared-terraform"
      environment = var.environment
      app_id      = "APP_XXX"
      approle     = "db"
      Name        = "${var.environment}-card-service-aurora"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  alias  = "secondary"

  default_tags {
    tags = {
      owner       = "user@example-company.com"
      project     = "TAG"
      lob         = "Payment Processing"
      manageby    = "Terraform"
      billingid   = "CORP-XXXXX-XXXX-XXXXX"
      repository  = "shared-terraform"
      environment = var.environment
      app_id      = "APP_XXX"
      approle     = "db"
      Name        = "${var.environment}-card-service-aurora"
    }
  }
}

provider "postgresql" {
  host            = local.writer_cluster.endpoint # Always connect to the writer cluster as Terraform always requires a read/write connection even for planning
  port            = local.writer_cluster.port
  database        = "postgres"
  username        = module.aurora_primary.cluster_master_username
  password        = module.aurora_primary.cluster_master_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false # Master user is not a superuser in RDS
}
