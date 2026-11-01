# iam.tf
# Part of the IAM roles and policies module.

resource "aws_iam_role" "payments_scheduler_ecs_api_region_role" {
  name               = "${var.environment}_${var.aws_region}_payments_scheduler_ecs_api_role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.payments_scheduler_assume_role_policy.json
}

resource "aws_iam_instance_profile" "payments_scheduler_ecs_api_region_profile" {
  name = "${var.environment}_${var.aws_region}_payments_scheduler_ecs_api_profile"
  role = aws_iam_role.payments_scheduler_ecs_api_region_role.name
}

resource "aws_iam_policy" "payments_scheduler_ecs_api_read_parameter_store" {
  name        = "${var.environment}_${var.aws_region}_payments_scheduler_ecs_api_read_param_store"
  path        = "/"
  description = "additional permissions for api fargate containers"
  policy      = data.aws_iam_policy_document.payments_scheduler_read_ecs_api_parameters.json
}

resource "aws_iam_policy" "payments_scheduler_ecs_container_permissions" {
  name        = "${var.environment}_${var.aws_region}_payments_scheduler_ecs_container_permissions"
  path        = "/"
  description = "Caution: Every container gets these permissions including support "
  policy      = data.aws_iam_policy_document.payments_scheduler_all_container_permissions.json
}

resource "aws_iam_role_policy_attachment" "payments_scheduler_ecs_container_to_ecs_api_region" {
  role       = aws_iam_role.payments_scheduler_ecs_api_region_role.name
  policy_arn = aws_iam_policy.payments_scheduler_ecs_container_permissions.arn
}

resource "aws_iam_role_policy_attachment" "payments_scheduler_ecs_api_read_parameters_to_ecs_api_region" {
  role       = aws_iam_role.payments_scheduler_ecs_api_region_role.name
  policy_arn = aws_iam_policy.payments_scheduler_ecs_api_read_parameter_store.arn
}

data "aws_iam_policy_document" "payments_scheduler_read_ecs_api_parameters" {
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
      values   = ["*mock-service*", "*api*", "*internal-api*"]
    }
    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "ssm:resourceTag/Environment"
      values   = [var.environment]
    }
  }
}

data "aws_iam_policy_document" "payments_scheduler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "payments_scheduler_all_container_permissions" {
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
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/env.${var.environment}/role.all/*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/env.${var.environment}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      "arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.environment}-${var.aws_region}-*"
    ]
  }
}

data "aws_iam_policy_document" "payments_scheduler_ecs_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "payments_scheduler_ecs_policy_document" {
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
      "secretsmanager:ListSecrets",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

# IAM follows the principle of least privilege.
resource "aws_iam_role" "payments_scheduler_ecs_task_role" {
  assume_role_policy = data.aws_iam_policy_document.payments_scheduler_ecs_assume_role_policy_document.json
  name               = "${var.environment}-${var.aws_region}-payments-scheduler-ecs-task-role"
}

resource "aws_iam_policy" "payments_scheduler_cloudwatch_logs_policy" {
  description = "Caution: These apply to all containers in the cluster"
  name        = "${var.environment}-${var.aws_region}-payments-scheduler-ecs-logs-policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.payments_scheduler_ecs_policy_document.json
}

resource "aws_iam_role_policy_attachment" "payments_scheduler_ecs_task_role_policy_attachment" {
  policy_arn = aws_iam_policy.payments_scheduler_cloudwatch_logs_policy.arn
  role       = aws_iam_role.payments_scheduler_ecs_task_role.name
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "payments-scheduler-ecs-task-execution-role-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.payments_scheduler_ecs_task_role.name
}
