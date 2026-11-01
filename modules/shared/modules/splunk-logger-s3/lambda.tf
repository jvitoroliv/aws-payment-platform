# lambda.tf
# Part of the Lambda function definitions module.

### Splunk Lambda
resource "aws_lambda_function" "splunklogger_s3" {
  function_name = "${var.environment}-${var.aws_region}-splunklogger-s3-lambda"
  handler       = "lambda_function.lambda_handler"
  filename      = "${path.module}/function/splunk_logger_s3.zip"
  layers = [
    # https://github.com/DataDog/datadog-lambda-extension/releases
    "arn:aws:lambda:${var.aws_region}:111111111109:layer:Datadog-Extension:58",
    # https://github.com/DataDog/datadog-lambda-python/releases
    "arn:aws:lambda:${var.aws_region}:111111111109:layer:Datadog-Python313:109"
  ]

  memory_size      = var.memory_size
  timeout          = "300"
  publish          = true
  role             = aws_iam_role.splunklogger_s3_role.arn
  runtime          = "python3.13"
  source_code_hash = data.archive_file.lambda_splunk_logger_s3.output_base64sha256

  environment {
    variables = {
      SPLUNK_HEC_TOKEN             = local.splunk_token.token
      SPLUNK_HEC_URL               = var.splunk_dest
      DD_SITE                      = "datadoghq.com"
      DD_API_KEY                   = local.datadog_secret.datadog-api-key
      DD_LAMBDA_HANDLER            = "lambda_function.lambda_handler"
      DD_TRACE_ENABLED             = true
      DD_SERVICE                   = "splunk"
      DD_SERVERLESS_APPSEC_ENABLED = false
      DD_MERGE_XRAY_TRACES         = false
      DD_FLUSH_TO_LOG              = true
      DD_ENV                       = var.environment
      DD_CAPTURE_LAMBDA_PAYLOAD    = false

    }
  }

  tags = {
    Environment = var.environment,
  }

  vpc_config {
    security_group_ids = [aws_security_group.splunk_logger_s3_sg.id]
    subnet_ids         = var.aws_private_subnets
  }
}

resource "aws_security_group" "splunk_logger_s3_sg" {
  name        = "splunk_logger_s3_lambda"
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
