# iam.tf
# Manages IAM roles and policies resources.

resource "aws_iam_instance_profile" "sftp_instance_region_role" {
  name = "temp_${var.environment}_${var.aws_region}_sftp_instance_role"
  role = aws_iam_role.sftp_instance_role.name
}

resource "aws_iam_role" "sftp_instance_role" {
  name               = "${var.environment}_${var.aws_region}_sftp_instance_role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "sftp_instance_attachment" {
  role       = aws_iam_role.sftp_instance_role.name
  policy_arn = aws_iam_policy.sftp_instance_perms.arn
}

resource "aws_iam_policy" "sftp_instance_perms" {
  name        = "temp_${var.environment}_${var.aws_region}_sftp_instance_perms"
  path        = "/"
  description = "support instance policy"
  policy      = data.aws_iam_policy_document.minimal_instance_perms.json
}

// update
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

// copy of AWS managed policy:   "aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
// can't import by ARN because of issue: https://github.com/terraform-providers/terraform-provider-aws/issues/6072
// so had to copy/paste it
// TODO: update
data "aws_iam_policy_document" "AmazonEC2RoleforSSM" {
  source_policy_documents = [
    <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ds:CreateComputer",
                "ds:DescribeDirectories"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetEncryptionConfiguration",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
  ]
  // temporarily added this unnecessary statement to work around an error
  // Error: data.aws_iam_policy_document.minimal_instance_perms: "statement": required field is not set
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }
}
data "aws_iam_policy_document" "minimal_instance_perms" {
  source_policy_documents = [data.aws_iam_policy_document.AmazonEC2RoleforSSM.json]

  // add statements here to override AmazonEC2RoleforSSM with more permissive/restrictive statements
  // temporarily added this unnecessary statement to work around an error
  // Error: data.aws_iam_policy_document.minimal_instance_perms: "statement": required field is not set
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
}