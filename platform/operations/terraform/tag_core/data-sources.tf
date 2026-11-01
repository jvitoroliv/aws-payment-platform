# data-sources.tf
# Part of the data source lookups module.

### Data Sources
data "aws_region" "current" {}

data "aws_vpc" "current" {
  id = var.aws_vpc_id
}

data "aws_secretsmanager_secret_version" "datadog-api-key" {
  secret_id = local.datadog_secret
}

data "aws_secretsmanager_secret" "artifactory" {
  name = local.artifactory_secret
}

data "aws_ssm_parameter" "crowdstrike-cid" {
  name = "/crowdstrike/cid"
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = local.state_bucket[var.environment]
    dynamodb_table = "tag-${local.environment ? "subprod" : "prod"}-state-store"
    key            = local.state_key
    region         = data.aws_region.current.name
  }
}

data "terraform_remote_state" "chronos" {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = local.state_bucket[var.environment]
    dynamodb_table = local.chronos_dynamodb_table
    key            = local.chronos_state_key
    region         = data.aws_region.current.name
  }
}

data "terraform_remote_state" "this" {
  backend = "s3"
  config = {
    bucket = local.state_bucket[var.environment]
    key    = "${var.environment}.tfstate"
    region = var.aws_region
  }
}

resource "terraform_data" "previous_active_region" {
  input = var.active_region != "" ? var.active_region : data.terraform_remote_state.this.outputs.previous.active_region

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    precondition {
      condition     = var.active_region != "" ? true : try(data.terraform_remote_state.this.outputs.previous.active_region != "", false)
      error_message = "The variable 'active_region' must be set to a non-empty string on the first plan/apply as it is not stored in the state yet. On subsequent runs, 'active_region' can be an empty string and the current active region from state will be used."
    }
  }
}

resource "terraform_data" "previous_mock_version" {
  input = var.mock_version != "" ? var.mock_version : data.terraform_remote_state.this.outputs.previous.mock_version

  lifecycle {
    precondition {
      condition     = var.mock_version != "" ? true : try(data.terraform_remote_state.this.outputs.previous.mock_version != "", false)
      error_message = "The variable 'mock_version' must be set to a non-empty string on the first plan/apply as it is not stored in the state yet. On subsequent runs, 'mock_version' can be an empty string and the services will use the same Docker image tag as they currently have."
    }
  }
}
