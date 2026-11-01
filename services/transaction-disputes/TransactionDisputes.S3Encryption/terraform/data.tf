# data.tf
# Part of the data source lookups module.

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_vpcs" "vpc" {
  tags = {
    Name = local.vpc_name[terraform.workspace]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.vpc.ids[0]]
  }

  tags = {
    NetworkTier = "privatezone"
  }
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      # S3 permissions for file migration operations
      "s3:GetObject",
      "s3:GetObjectMetadata",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListObjectsV2",
      # SQS permissions for message consumption
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "lambda:InvokeFunction",
      "secretsmanager:ListSecrets",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
  }
}

data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_ecs_cluster" "ecs_fargate_cluster" {
  cluster_name = local.ecs_cluster_name
}
data "aws_security_group" "PaymentServiceTLS" {
  vpc_id = data.aws_vpcs.vpc.ids[0]

  tags = {
    Name = "PaymentServiceTLS"
  }
}
