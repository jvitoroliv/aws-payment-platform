# iam-job.tf
# Part of the IAM roles and policies module.

resource "aws_iam_instance_profile" "tagcore_instance_profile" {
  name = "${var.environment}_${var.aws_region}_tagcore_prof"
  role = aws_iam_role.tagcore_instance_region_role.name
}

resource "aws_iam_role" "tagcore_instance_region_role" {
  name               = "${var.environment}_${var.aws_region}_tagcore_role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "can_read_tagcore_parameters" {
  name        = "${var.environment}_${var.aws_region}_tagcore_read_param_store"
  path        = "/"
  description = "can_read_auth_parameters"
  policy      = data.aws_iam_policy_document.can_read_tagcore_parameters.json
}

resource "aws_iam_policy" "instance_perms" {
  name        = "${var.environment}_${var.aws_region}_tagcore_perms"
  path        = "/"
  description = "Caution: Every container gets these permissions including support "
  policy      = data.aws_iam_policy_document.all_instance_perms.json
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "instance_perms_to_tagcore_server_region" {
  role       = aws_iam_role.tagcore_instance_region_role.name
  policy_arn = aws_iam_policy.instance_perms.arn
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "tagcore_instance_role_can_read_tagcore_parameters" {
  role       = aws_iam_role.tagcore_instance_region_role.name
  policy_arn = aws_iam_policy.can_read_tagcore_parameters.arn
}


data "aws_iam_policy_document" "can_read_tagcore_parameters" {
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
      values   = ["*mock-service*", "*tagcore*"]
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
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "s3:Get*",
      "s3:Put*",
      "s3:List*",
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.environment}-*-app-artifacts-app/*",
      "arn:aws:s3:::${var.environment}-*-app-artifacts-app",
    ]
  }

  statement {
    actions = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    effect  = "Allow"
    resources = [
      "arn:aws:kms:::*${var.environment}*",
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

resource "aws_security_group" "tagcore" {
  name   = format("tc-sg-fgate-%s", var.environment)
  vpc_id = var.aws_vpc_id
  ingress {
    from_port   = 1025
    to_port     = 1025
    protocol    = "tcp"
    cidr_blocks = [local.internal_cidr]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [local.internal_cidr]
  }
  egress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "mongo"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 465
    to_port     = 465
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 2121
    to_port     = 2121
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "sftp mastercard"
    from_port   = 44323
    to_port     = 44323
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "sentential"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}