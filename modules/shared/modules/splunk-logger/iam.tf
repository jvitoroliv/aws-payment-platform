### Splunk Logger IAM Roles

#Splunk Logger IAM Role
resource "aws_iam_role" "splunklogger_role" {
  name = "${var.environment}-${var.aws_region}-shared-splunklogger-role"

  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#Splunk Logger IAM Policy
resource "aws_iam_policy" "splunklogger_policy" {
  name        = "${var.environment}-${var.aws_region}-shared-splunklogger-policy"
  path        = "/"
  description = "IAM policy for Splunk Logging Lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

#Splunk Logger Policy Attachment
# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "splunklogger_attachment" {
  role       = aws_iam_role.splunklogger_role.name
  policy_arn = aws_iam_policy.splunklogger_policy.arn
}

#Splunk Logger Policy attach AWS managed AWSLambdaVPCAccessExecutionRole policy
# Allow Lambda to manage its own ENIs in the VPC
resource "aws_iam_role_policy_attachment" "splunklogger_attachment_vpc_execution_role" {
  role       = aws_iam_role.splunklogger_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
