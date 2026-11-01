# iam.tf
# Part of the IAM roles and policies module.

resource "aws_iam_policy" "instance_perms" {
  name        = "${var.environment}_${var.aws_region}_test_harness_container_perms"
  path        = "/"
  description = "Caution: Every container gets these permissions including support "
  policy      = data.aws_iam_policy_document.all_instance_perms.json
}

# END Roles

# Policies
# Trust policy — defines which principals can assume this role via STS
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "all_instance_perms" {
  statement {
    actions = [
      "s3:Get*",
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.environment}-*-app-artifacts-app/*",
      "arn:aws:s3:::${var.environment}-*-app-artifacts-app",
      "arn:aws:sqs::*-${var.environment}",
      "arn:aws:sqs::scheduled-event-${var.environment}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricAlarm",
      "sns:ListTopics",
      "ec2:CreateTags",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:DescribeInstanceStatus",
      "ec2:AttachVolume",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
      "elasticfilesystem:DescribeFileSystems",
      "sqs:*",
      "secretsmanager:ListSecrets",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:*"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_number}:parameter/env.${var.environment}/role.all/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      "arn:aws:sns:${var.aws_region}:${var.aws_account_number}:${var.environment}-${var.aws_region}-*"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]
    resources = ["arn:aws:logs:*"]
  }
}
