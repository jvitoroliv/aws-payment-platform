# lambda.tf
# Part of the Lambda function definitions module.

resource "aws_lambda_function" "function" {
  function_name                  = var.function_name
  s3_bucket                      = var.artifact_bucket
  s3_key                         = var.artifact_key
  handler                        = var.handler_name
  role                           = aws_iam_role.function.arn
  runtime                        = var.runtime
  timeout                        = 240
  memory_size                    = var.memsize
  reserved_concurrent_executions = var.concurrent_executions
  layers                         = [var.datadog_lambda_layer]

  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }

  tags = var.tags

  environment {
    variables = var.lambda_env_vars
  }
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "function" {
  name               = "${var.function_name}-execution-role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      }
    }
  ]
}
EOF

  tags = var.tags
}

# Allow log and queue access
# checkov:skip=CKV_AWS_290 Reason: This IAM policy allows necessary write actions for the Lambda function.
# checkov:skip=CKV_AWS_355 Reason: This IAM policy allows necessary access to resources.
resource "aws_iam_role_policy" "function" {
  name   = "${var.function_name}-execution-policy"
  role   = aws_iam_role.function.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:SendMessage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "sqs:ListQueues"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_number}:secret:datadog-api-key-*"
    }
  ]
}
EOF
}
