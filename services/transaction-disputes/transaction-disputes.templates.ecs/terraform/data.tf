# data.tf
# Manages data source lookups resources.

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
      "s3:*",
      "sqs:*",
      "dynamodb:*",
      "lambda:InvokeFunction",
      "secretsmanager:ListSecrets",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
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

data "aws_secretsmanager_secret" "jfrog_secret" {
  name = local.jfrog_secret_name
}

data "aws_secretsmanager_secret" "splunk_secret" {
  name = local.splunk_secret_name
}

data "aws_secretsmanager_secret_version" "payment-service-datadog" {
  secret_id = "service-datadog-api-key"
}

data "aws_security_group" "PaymentServiceTLS" {
  vpc_id = data.aws_vpcs.vpc.ids[0]

  tags = {
    Name = "PaymentServiceTLS"
  }
}
