# jenkins-agent-role.tf
# Part of the jenkins-agent-role Terraform configuration module.

resource "aws_iam_instance_profile" "test_profile" {
  count = var.aws_region == "us-east-1" ? 1 : 0
  name  = "${var.environment}_jenkins_instance_profile"
  role  = aws_iam_role.jenkins_role[0].name
}

# IAM follows the principle of least privilege.
resource "aws_iam_role" "jenkins_role" {
  count = var.aws_region == "us-east-1" ? 1 : 0
  name  = "${var.environment}_jenkins_role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "jenkins_group_policy" {
  count      = var.aws_region == "us-east-1" ? 1 : 0
  role       = aws_iam_role.jenkins_role[0].name
  policy_arn = aws_iam_policy.jenkins_policy[0].arn
}

resource "aws_iam_policy" "jenkins_policy" {
  count  = var.aws_region == "us-east-1" ? 1 : 0
  name   = "${var.environment}_jenkins_policy"
  policy = data.aws_iam_policy_document.jenkins_policy_document.json
}

data "aws_iam_policy_document" "jenkins_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    resources = ["*"]
    effect    = "Allow"
    not_actions = [
      "iam:*",
      "organizations:*"
    ]
  }

  statement {
    actions = [
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy"
    ]
    resources = ["*"]
    effect    = "Allow"
    condition {
      test = "ArnNotEquals"
      values = [
        "arn:aws:iam::aws:policy/AdministratorAccess",
        "arn:aws:iam::aws:policy/job-function/Billing",
        "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator",
        "arn:aws:iam::aws:policy/job-function/DataScientist",
        "arn:aws:iam::aws:policy/job-function/NetworkAdministrator",
        "arn:aws:iam::aws:policy/PowerUserAccess",
        "arn:aws:iam::aws:policy/SecurityAudit",
        "arn:aws:iam::aws:policy/job-function/SupportUser",
        "arn:aws:iam::aws:policy/job-function/SystemAdministrator",
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
        "arn:aws:iam::aws:policy/aws-service-role/AWSOrganizationsServiceTrustPolicy",
        "arn:aws:iam::aws:policy/IAM*"
      ]
      variable = "iam:PolicyArn"
    }
  }

  statement {
    resources = ["*"]
    effect    = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteInstanceProfile",
      "iam:UpdateAssumeRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteRole",
      "iam:UpdateRoleDescription",
      "iam:DeleteServiceLinkedRole",
      "iam:PutRolePolicy",
      "iam:CreateInstanceProfile",
      "iam:CreateServiceLinkedRole",
      "iam:GenerateServiceLastAccessedDetails",
      "iam:List*",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UntagPolicy",
      "iam:UntagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:GetPolicy*",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:PassRole",
      "iam:GetServiceLastAccessed*",
      "iam:GetRole*",
      "iam:GetInstanceProfile",
      "iam:Simulate*",
      "iam:GetAccount*"
    ]
  }

  statement {
    resources = ["*"]
    effect    = "Allow"
    actions = [
      "ds:AuthorizeApplication",
      "ds:CheckAlias",
      "ds:CreateAlias",
      "ds:CreateIdentityPoolDirectory",
      "ds:DeleteDirectory",
      "ds:DescribeDirectories",
      "ds:DescribeTrusts",
      "ds:UnauthorizeApplication",
      "quicksight:CreateUser",
      "quicksight:CreateAdmin",
      "quicksight:Subscribe",
      "quicksight:GetGroupMapping",
      "quicksight:SearchDirectoryGroups",
      "quicksight:SetGroupMapping",
      "quicksight:Unsubscribe"
    ]
  }

  statement {
    actions = ["iam:*"]
    resources = [
      "arn:aws:iam::${var.aws_account_number}:role/SAML*"
    ]
    effect = "Deny"
  }
}
