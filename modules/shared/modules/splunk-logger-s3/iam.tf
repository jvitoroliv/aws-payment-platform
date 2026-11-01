### Splunk Logger IAM Roles

#Splunk Logger IAM Role
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "splunklogger_s3_role" {
  name = "${var.environment}-${var.aws_region}-shared-splunklogger-s3-role"

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
resource "aws_iam_policy" "splunklogger_s3_policy" {
  name        = "${var.environment}-${var.aws_region}-shared-splunklogger-s3-policy"
  path        = "/"
  description = "IAM policy for Splunk S3 Logging Lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "lambdaGetObject",
        "Effect": "Allow",
        "Action": "s3:GetObject",
        "Resource": "${data.aws_s3_bucket.access_logs.arn}/*"
    },
    {
        "Sid": "lambdaSqsActions",
        "Effect": "Allow",
        "Action": [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
        ],
        "Resource": "${aws_sqs_queue.splunklogger_s3.arn}" 
    }
  ]
}
EOF
}

#Splunk Logger S3 Policy Attachment
# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "splunklogger_s3_attachment" {
  role       = aws_iam_role.splunklogger_s3_role.name
  policy_arn = aws_iam_policy.splunklogger_s3_policy.arn
}

#Splunk Logger Policy attach AWS managed AWSLambdaVPCAccessExecutionRole policy
# Allow Lambda to manage its own ENIs in the VPC
resource "aws_iam_role_policy_attachment" "splunklogger_s3_attachment_vpc_execution_role" {
  role       = aws_iam_role.splunklogger_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
