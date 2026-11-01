# iam-human-support.tf
# Part of the IAM roles and policies module.

###Roles###
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "support_role" {
  count                = var.aws_region == "us-east-1" ? 1 : 0
  name                 = "${var.environment}_support"
  max_session_duration = 43200
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy   = data.aws_iam_policy_document.saml_support_role_can_assume_with_mfa.json
  path                 = "/human/"
}

###Policies###
resource "aws_iam_policy" "allow_sqs" {
  count       = var.aws_region == "us-east-1" ? 1 : 0
  name        = "${var.environment}_${var.aws_region}_allow_sqs"
  path        = "/"
  description = "Allow message support role sending/deleting of queue messages"
  policy      = data.aws_iam_policy_document.message_support_access.json
}

// Policy for prod SAMLSupportUser role to allow it assume message_support roles
resource "aws_iam_policy" "allow_prod_saml_assume_policy" {

  name        = "${var.environment}-${var.aws_region}-assume_message_support"
  description = "Policy to allow the ${var.environment} SAMLSupportUser role to assume the message_support roles."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:iam::*:role/human/*_message_support"
      ]
    }
  ]
}
EOF
}

// This policy is being built to override aws_arn_policies on message_support role
// This will deny users access to cloudwatch:logs to prevent senstive data.
resource "aws_iam_policy" "deny_kms_logs" {
  count       = var.aws_region == "us-east-1" ? 1 : 0
  name        = "${var.environment}_${var.aws_region}_deny_kms_logs"
  path        = "/"
  description = "Deny Access to message support users from viewing Cloudwatch Logs, and decrypting via KMS"
  policy      = data.aws_iam_policy_document.deny_kms_support_access.json
}

resource "aws_iam_policy" "allow_ssm_session" {
  count       = var.aws_region == "us-east-1" ? 1 : 0
  name        = "${var.environment}_${var.aws_region}_allow_ssm_session"
  path        = "/"
  description = "Allow support users start and end ssm sessions."
  policy      = data.aws_iam_policy_document.allow_start_end_ssm_session.json
}


resource "aws_iam_policy" "allow_secrets_access" {
  count       = (var.aws_region == "us-east-1" && var.environment!="prod") ? 1 : 0
  name        = "${var.environment}_${var.aws_region}_allow_secrets_access"
  path        = "/"
  description = "Allow support users to get secrets access for PGP keys."
  policy      = data.aws_iam_policy_document.allow_secrets_access.json
}

###Policy Attachment###
resource "aws_iam_role_policy_attachment" "message_support_role_can_view_basic_aws_stuff" {
  count      = var.aws_region == "us-east-1" ? 1 : 0
  role       = aws_iam_role.support_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "deny_support_readonly_access" {
  count      = var.aws_region == "us-east-1" ? 1 : 0
  role       = aws_iam_role.support_role[0].name
  policy_arn = aws_iam_policy.deny_kms_logs[0].arn
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "allow_sqs_message_support" {
  count      = var.aws_region == "us-east-1" ? 1 : 0
  role       = aws_iam_role.support_role[0].name
  policy_arn = aws_iam_policy.allow_sqs[0].arn
}

resource "aws_iam_role_policy_attachment" "allow_support_role_ssm_sessions" {
  count      = var.aws_region == "us-east-1" ? 1 : 0
  role       = aws_iam_role.support_role[0].name
  policy_arn = aws_iam_policy.allow_ssm_session[0].arn
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "allow_support_role_secrets_access" {
  count      = (var.aws_region == "us-east-1" && var.environment!="prod") ? 1 : 0
  role       = aws_iam_role.support_role[0].name
  policy_arn = aws_iam_policy.allow_secrets_access[0].arn
}

###Policy Document###
data "aws_iam_policy_document" "deny_kms_support_access" {
  statement {
    effect = "Deny"
    actions = [
      "logs:*",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_start_end_ssm_session" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:TerminateSession",
      "ssm:ResumeSession"
    ]
    resources = ["*"]
  }
}


data "aws_iam_policy_document" "allow_secrets_access" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue","secretsmanager:DescribeSecret","secretsmanager:GetResourcePolicy","secretsmanager:ListSecretVersionIds"]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_number}:secret:${var.environment}-pgp-private-key-*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

}

// This role can only be assumed by prod SAMLSupportUser role
data "aws_iam_policy_document" "saml_support_role_can_assume_with_mfa" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_number}:role/SAMLSupportUser"]
    }
  }
}

data "aws_iam_policy_document" "message_support_access" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      "arn:aws:sqs:us-east-1:${var.aws_account_number}:chronos-${var.environment}-us-east-1-*",
      "arn:aws:sqs:us-east-1:${var.aws_account_number}:${var.environment}-us-east-1-*",
      "arn:aws:sqs:us-west-2:${var.aws_account_number}:chronos-${var.environment}-us-west-2-*",
      "arn:aws:sqs:us-west-2:${var.aws_account_number}:${var.environment}-us-west-2-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage"
    ]
    resources = [
      "arn:aws:sqs:us-east-1:${var.aws_account_number}:chronos-${var.environment}-*-error",
      "arn:aws:sqs:us-east-1:${var.aws_account_number}:${var.environment}-*-error",
    ]
  }
}
