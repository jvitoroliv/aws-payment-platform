# provider.tf
# Part of the provider Terraform configuration module.

# local

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  backend "local" {}
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.29.1"
    }
  }
}

provider "aws" {
  access_key                  = "mock_access_key"
  region                      = var.aws_region
  s3_use_path_style           = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway       = "http://${var.aws_endpoint}:4566"
    cloudwatch       = "http://${var.aws_endpoint}:4566"
    cloudwatchevents = "http://${var.aws_endpoint}:4566"
    cloudwatchlogs   = "http://${var.aws_endpoint}:4566"
    dynamodb         = "http://${var.aws_endpoint}:4566"
    ec2              = "http://${var.aws_endpoint}:4566"
    es               = "http://${var.aws_endpoint}:4566"
    firehose         = "http://${var.aws_endpoint}:4566"
    iam              = "http://${var.aws_endpoint}:4566"
    kinesis          = "http://${var.aws_endpoint}:4566"
    kms              = "http://${var.aws_endpoint}:4566"
    lambda           = "http://${var.aws_endpoint}:4566"
    redshift         = "http://${var.aws_endpoint}:4566"
    route53          = "http://${var.aws_endpoint}:4566"
    s3               = "http://${var.aws_endpoint}:4566"
    secretsmanager   = "http://${var.aws_endpoint}:4566"
    ses              = "http://${var.aws_endpoint}:4566"
    sns              = "http://${var.aws_endpoint}:4566"
    sqs              = "http://${var.aws_endpoint}:4566"
    ssm              = "http://${var.aws_endpoint}:4566"
    stepfunctions    = "http://${var.aws_endpoint}:4566"
    sts              = "http://${var.aws_endpoint}:4566"
  }
}
