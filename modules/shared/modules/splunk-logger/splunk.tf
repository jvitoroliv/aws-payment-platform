# splunk.tf
# Manages splunk Terraform configuration resources.

### Splunk Lambda
resource "aws_lambda_function" "splunklogger" {
  function_name = "${var.environment}-${var.aws_region}-splunklogger-lambda"
  handler       = "/opt/nodejs/node_modules/datadog-lambda-js/handler.handler"
  layers = [
    # https://github.com/DataDog/datadog-lambda-extension/releases
    "arn:aws:lambda:${var.aws_region}:111111111109:layer:Datadog-Extension:58",
    # https://github.com/DataDog/datadog-lambda-js/releases
    "arn:aws:lambda:${var.aws_region}:111111111109:layer:Datadog-Node22-x:125"
  ]
  memory_size       = var.memory_size
  publish           = true
  role              = aws_iam_role.splunklogger_role.arn
  runtime           = "nodejs22.x"
  s3_bucket         = var.source_s3_bucket
  s3_key            = var.source_s3_key
  s3_object_version = data.aws_s3_object.splunklogger_source.version_id
  source_code_hash  = data.archive_file.lambda_splunk_logger.output_base64sha256
  timeout           = "60"
  environment {
    variables = {
      SPLUNK_HEC_TOKEN             = local.splunk_token.token
      SPLUNK_HEC_URL               = var.splunk_dest
      DD_SITE                      = "datadoghq.com"
      DD_API_KEY                   = local.datadog_secret.datadog-api-key
      DD_LAMBDA_HANDLER            = "index.handler"
      DD_TRACE_ENABLED             = true
      DD_SERVICE                   = "splunk"
      DD_SERVERLESS_APPSEC_ENABLED = false
      DD_MERGE_XRAY_TRACES         = false
      DD_FLUSH_TO_LOG              = true
      DD_ENV                       = var.environment
      DD_CAPTURE_LAMBDA_PAYLOAD    = false

    }
  }
  vpc_config {
    security_group_ids = [aws_security_group.splunk_logger_sg.id]
    subnet_ids         = var.aws_private_subnets
  }
}

resource "aws_lambda_permission" "splunklogger-cloudwatch" {
  statement_id  = "splunklogger-cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.splunklogger.arn
  principal     = "logs.${var.aws_region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${var.aws_region}:${var.aws_account_number}:log-group:*:*"
}

resource "aws_security_group" "splunk_logger_sg" {
  name        = "splunk_logger_lambda"
  description = "Uses our VPC for shipping logs to splunk"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "udp"
    to_port     = 443
  }
  ingress {
    from_port = 0
    protocol  = "-1"
    self      = true
    to_port   = 0
  }
  vpc_id = var.aws_vpc_id
}
