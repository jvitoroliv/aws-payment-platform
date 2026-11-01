# Variables
# =================================================
# vpc-level
# Type constraint catches misuse at plan time.
variable "region"        { }
variable "environment"   { }

# Locals
# =================================================
locals {
  region_keys = {
    "us-east-1"      = "UE1"
    "us-west-2"      = "UW2"
  }

  env_keys = {
    "dev"   = "D"
    "uat"   = "U"
    "stage" = "S"
    "demo"  = "C"
    "prod"  = "P"
    "qa"    = "Q"
  }

  short_region_keys = {
    "us-east-1" = "E"
    "us-west-2" = "W"
  }
}

# Lambas
# =================================================

# DrainSQSToS3
# -------------------------------------------------

# DrainSQSToS3 S3 bucket
# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket" "drain_sqs_to_s3_bucket" {
  bucket              = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-sqs-drain-${var.region}-${var.environment}"
  region              = "${var.region}"

  lifecycle_rule {
    id      = "delete after 90 days"
    enabled = true
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "drain_sqs_block" {
  bucket = "${aws_s3_bucket.drain_sqs_to_s3_bucket.id}"

    block_public_acls       = true
    block_public_policy     = true
    restrict_public_buckets = true
    ignore_public_acls      = true
}

# DrainSQSToS3 IAM policy
# Trust policy — defines which principals can assume this role via STS
data "aws_iam_policy_document" "lambda_assume_role_policy_document" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_drain_sqs_to_s3_policy_document" {
  statement {
    sid     = ""
    
    actions = [
      "s3:*",
      "sqs:*"
    ]
    
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_drain_sqs_to_s3_policy" {
  name = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-lambda-drainSQS-policy"
  policy = "${data.aws_iam_policy_document.lambda_drain_sqs_to_s3_policy_document.json}"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DrainSQSToS3 role
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "lambda_drain_sqs_to_s3_role" {
  name               = "${lower(lookup(local.region_keys, var.region))}-cpt-enc-shrd-${var.environment}-lambda-drainSQS-role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy_document.json}"
  description        = "Role for DrainSQSToS3 Lambda"
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole-policy-attach" {
  role       = "${aws_iam_role.lambda_drain_sqs_to_s3_role.id}"
  policy_arn = "${data.aws_iam_policy.AWSLambdaBasicExecutionRole-policy.arn}"
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "drain_sqs_to_s3-policy-attach" {
  role       = "${aws_iam_role.lambda_drain_sqs_to_s3_role.id}"
  policy_arn = "${aws_iam_policy.lambda_drain_sqs_to_s3_policy.arn}"
}

# DrainSQSToS3 lambda itself
resource "aws_lambda_function" "drain_sqs_to_s3_lambda" {
  filename      = "./DrainQueueToS3.zip"
  function_name = "DrainQueueToS3"
  role          = "${aws_iam_role.lambda_drain_sqs_to_s3_role.arn}"
  handler       = "DrainQueueToS3::DrainQueueToS3.Function::FunctionHandler"
  timeout       = 900 # 15m

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${base64sha256(file("./DrainQueueToS3.zip"))}"

  runtime = "dotnetcore3.1"
}
# -------------------------------------------------