
# Variables
# -----------------------------------------------------------------------
variable "name"                                { }
variable "region"                              { }
variable "partition"                           { }
variable "account_id"                          { }
variable "environment"                         { }
variable "memory_size_mb"                      { default = 512 }
variable "timeout_secs"                        { default = 60 }
variable "bucket_name"                         { }
variable "prefix_name"                         { default = "" }
# Input validation ensures callers provide sane values.
variable "object_age_minutes_min"              { default = 60 }
variable "object_age_minutes_max"              { default = 120 }
variable "tags"                                { type = "map" }
variable "description"                         { default = "Monitor the age of S3 objects" }
variable "schedule_expression"                 { default = "cron(0 */1 * * ? *)" }  # every hour


# Data
# -----------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_policy" {

  statement {
    sid = "logevents"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${var.partition}:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${var.name}:*"
    ]
  }

  statement {
    sid = "loggroup"

    actions = [
      "logs:CreateLogGroup"
    ]

    resources = [
      "arn:${var.partition}:logs:${var.region}:${var.account_id}:*"
    ]
  }

  statement {
    sid = "lambda"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "s3"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:${var.partition}:s3:::${var.bucket_name}"
    ]
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Resources
# -----------------------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name                  = "${var.name}-role"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy    = "${data.aws_iam_policy_document.lambda_assume_role.json}"
  force_detach_policies = true
  tags                  = "${var.tags}"
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy" "instance_policy" {
  name   = "${var.name}-instance-policy"
  role   = "${aws_iam_role.lambda_role.id}"
  policy = "${data.aws_iam_policy_document.lambda_policy.json}"
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_file = "${path.module}/function/monitor.js"
  output_path = "${path.module}/function/monitor.zip"
}

resource "aws_lambda_function" "s3monitor_lambda" {
  runtime          = "nodejs16.x"
  description      = "${var.description}"
  filename         = "${data.archive_file.function_zip.output_path}"
  source_code_hash = "${base64sha256(file("${data.archive_file.function_zip.output_path}"))}"
  function_name    = "${var.name}"
  role             = "${aws_iam_role.lambda_role.arn}"
  # role             = "arn:aws:iam::999999999999:role/service-role/TestMonitor-role-vhe35vba"
  handler          = "monitor.handler"
  memory_size      = "${var.memory_size_mb}"
  timeout          = "${var.timeout_secs}"
  publish          = true
  tags             = "${var.tags}"
  
  environment {
    variables = {
      BucketName          = "${var.bucket_name}",
      Prefix              = "${var.prefix_name}",
      Env                 = "${var.environment}",
      ObjectAgeMinutesMin = "${var.object_age_minutes_min}",
      ObjectAgeMinutesMax = "${var.object_age_minutes_max}",
      RunDate             = "null"  # use this for debugging from the AWS console
    }
  }
}

// cloudwatch cron to trigger this monitor
resource "aws_cloudwatch_event_rule" "s3_age_monitor_cloudwatch" {
  name                = "${var.name}-rule"
  description         = "Trigger the S3 overflow monitor lambda"
  schedule_expression = "${var.schedule_expression}"
  tags                = "${var.tags}"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "s3_age_monitor_cloudwatch_target" {
  rule      = "${aws_cloudwatch_event_rule.s3_age_monitor_cloudwatch.name}"
  target_id = "${aws_lambda_function.s3monitor_lambda.function_name}"
  arn       = "${aws_lambda_function.s3monitor_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.s3monitor_lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_account = "${var.account_id}"
  source_arn    = "${aws_cloudwatch_event_rule.s3_age_monitor_cloudwatch.arn}"
}

# Outputs
# =================================================
output "lambda_role_arn" { value = "${aws_iam_role.lambda_role.arn}" }
output "function_name" { value = "${aws_lambda_function.s3monitor_lambda.function_name}" }
output "lambda_arn" { value = "${aws_lambda_function.s3monitor_lambda.arn}" }
