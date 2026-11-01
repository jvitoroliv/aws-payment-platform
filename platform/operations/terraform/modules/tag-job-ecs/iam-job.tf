# iam-job.tf
# Part of the IAM roles and policies module.

resource "aws_iam_instance_profile" "job_instance_profile" {
  name = "${var.environment}_${var.aws_region}_job_profile"
  role = aws_iam_role.job_instance_region_role.name
}

resource "aws_iam_role" "job_instance_region_role" {
  name               = "${var.environment}_${var.aws_region}_job_role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "can_read_job_parameters" {
  name        = "${var.environment}_${var.aws_region}_job_read_param_store"
  path        = "/"
  description = "can_read_auth_parameters"
  policy      = data.aws_iam_policy_document.can_read_job_parameters.json
}

resource "aws_iam_policy" "instance_perms" {
  name        = "${var.environment}_${var.aws_region}_job_perms"
  path        = "/"
  description = "Caution: Every container gets these permissions including support "
  policy      = data.aws_iam_policy_document.all_instance_perms.json
}

resource "aws_iam_role_policy_attachment" "instance_perms_to_job_server_region" {
  role       = aws_iam_role.job_instance_region_role.name
  policy_arn = aws_iam_policy.instance_perms.arn
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "job_instance_role_can_read_job_parameters" {
  role       = aws_iam_role.job_instance_region_role.name
  policy_arn = aws_iam_policy.can_read_job_parameters.arn
}


data "aws_iam_policy_document" "can_read_job_parameters" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "ssm:resourceTag/Service"
      values   = ["*mock-service*", "*job*"]
    }
    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "ssm:resourceTag/Environment"
      values   = [var.environment]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}



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
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]
    resources = ["arn:aws:logs:*"]
  }

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
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/env.${var.environment}/role.all/*",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/env.${var.environment}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.environment}-${var.aws_region}-*"
    ]
  }
}