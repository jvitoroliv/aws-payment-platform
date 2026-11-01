# provider.tf
# Part of the provider Terraform configuration module.

#local 

# Provider versions pinned to minor — patch updates auto-applied, breaking changes blocked
terraform {
  required_version = ">=1.6.5"
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
      # version = "~> 5.46"
      # There seems to be a bug with version 5.96.0 to at least 5.98.0 of the AWS provider that causes an error with Localstack
      # v5.96.0 seems to introduce new API Gateway attributes: https://github.com/hashicorp/terraform-provider-aws/releases/tag/v5.96.0
      # Attempt to update this in the future to see if Localstack or the AWS provider has fixed this
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
  insecure                    = true

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

  default_tags {
    tags = {
      owner       = "user@example-company.com"
      project     = "TAG"
      lob         = "Payment Processing"
      managedby   = "Terraform"
      billingid   = "CORP-XXXXX-XXXX-XXXXX"
      repository  = "ps-tag-chronos"
      appid       = "APP_44815"
      approle     = "application"
      environment = var.environment
    }
  }
}
