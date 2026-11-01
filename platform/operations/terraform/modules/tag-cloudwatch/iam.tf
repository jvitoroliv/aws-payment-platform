# iam.tf
# Manages IAM roles and policies resources.

# IAM follows the principle of least privilege.
resource "aws_iam_role" "cloudwatch_role" {
  name               = "${var.environment}_${var.aws_region}_cloudwatch"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume_policy.json

  inline_policy {
    name   = "${var.environment}_${var.aws_region}_cloudwatch_policy"
    policy = data.aws_iam_policy_document.cloudwatch_policy.json
  }
}

data "aws_iam_policy_document" "cloudwatch_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_policy" {
  statement {
    actions   = ["sqs:*"]
    effect    = "Allow"
    resources = ["*"]
  }
}
