# trendmicro-iam.tf
# Part of the IAM roles and policies module.

######IAM Role and policy for Trend micro#######
data "aws_iam_policy_document" "trendmicro" {
  statement {
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSecurityGroups",
      "workspaces:DescribeWorkspaces",
      "workspaces:DescribeWorkspaceDirectories",
      "workspaces:DescribeWorkspaceBundles",
      "workspaces:DescribeTags",
      "iam:ListAccountAliases",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "sts:AssumeRole",
    ]

    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "trendmicropolicy" {
  name   = "trendmicro-access-policy"
  policy = "${data.aws_iam_policy_document.trendmicro.json}"
}

resource "aws_iam_role" "trendmicrorole" {
  name = "TrendMicroSaasRole"

  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {"AWS": "arn:aws:iam::999999999999:root"},
      "Effect": "Allow",
      "Sid": "",
      "Condition": {"StringEquals": {"sts:ExternalId" : "7377TrendSaas4247"}}
    }
  ]  
 }
EOF
}

resource "aws_iam_role_policy_attachment" "trendmicro" {
  role       = "${aws_iam_role.trendmicrorole.name}"
  policy_arn = "${aws_iam_policy.trendmicropolicy.arn}"
}
