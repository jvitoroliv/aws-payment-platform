# data-sources.tf
# Part of the data source lookups module.

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = local.state_bucket[var.environment]
    key    = local.state_key
    region = var.region
  }
}

data "aws_secretsmanager_secret_version" "datadog-api-key" {
  secret_id = local.datadog_secret
}

data "terraform_remote_state" "this" {
  backend = "s3"
  config = {
    bucket = local.state_bucket[var.environment]
    key    = "${var.environment}-${var.region}-chronos.tfstate"
    region = var.region
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

resource "terraform_data" "previous_code_version" {
  input = var.code_version != "" ? var.code_version : data.terraform_remote_state.this.outputs.previous.code_version

  lifecycle {
    precondition {
      condition     = var.code_version != "" ? true : try(data.terraform_remote_state.this.outputs.previous.code_version != "", false)
      error_message = "The variable 'code_version' must be set to a non-empty string on the first plan/apply as it is not stored in the state yet. On subsequent runs, 'code_version' can be an empty string and the Lambda Functions will use the code version as they currently have."
    }
  }
}