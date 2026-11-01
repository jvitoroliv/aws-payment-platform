# iam-th.tf
# Manages IAM roles and policies resources.

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "th_instance_region_role" {
  name               = "${var.environment}_${var.aws_region}_th_container_role_MOCK"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.th_assume_role_policy.json
}

output "th_iam_role_arn" {
  value = aws_iam_role.th_instance_region_role.arn
}

# Updated assume role policy for EKS service accounts
data "aws_iam_policy_document" "th_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_number}:oidc-provider/oidc.eks.${var.aws_region}.amazonaws.com/id/${var.eks_oidc_provider_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.${var.aws_region}.amazonaws.com/id/${var.eks_oidc_provider_id}:sub"
      values   = ["system:serviceaccount:ps-tag-test-harness:test-harness"]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.${var.aws_region}.amazonaws.com/id/${var.eks_oidc_provider_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "can_read_th_parameters" {
  name        = "${var.environment}_${var.aws_region}_can_read_th_parameters_fargate_MOCK"
  path        = "/"
  description = "can_read_auth_parameters"
  policy      = data.aws_iam_policy_document.can_read_th_parameters.json
}

data "aws_iam_policy_document" "can_read_th_parameters" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "secretsmanager:ListSecrets",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "instance_perms_to_th_server_region" {
  role       = aws_iam_role.th_instance_region_role.name
  policy_arn = aws_iam_policy.instance_perms.arn
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "th_instance_role_can_read_th_parameters" {
  role       = aws_iam_role.th_instance_region_role.name
  policy_arn = aws_iam_policy.can_read_th_parameters.arn
}
