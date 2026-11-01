# api_gateway.tf
# Part of the api_gateway Terraform configuration module.

locals {
  # https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-resource-policies-examples.html
  api_vpc_whitelist_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*",
            "Condition": {
                "StringNotEquals": {
                    "aws:sourceVpc": "${var.vpc_whitelist}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
        }
    ]
}
EOF
}

resource "aws_api_gateway_rest_api" "api" {
  name = var.function_name

  endpoint_configuration {
    types = [var.vpc_whitelist == "" ? "EDGE" : "PRIVATE"]
  }
}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  policy = var.vpc_whitelist == "" ? null : local.api_vpc_whitelist_policy
}

resource "aws_api_gateway_resource" "proxy-resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy-resource.id

  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy-resource.id

  http_method = "ANY"
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.function.invoke_arn

  integration_http_method = "POST"
}

resource "aws_lambda_permission" "lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_stage" "api" {
  stage_name    = var.environment
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
}

resource "aws_api_gateway_deployment" "api" {
  depends_on  = [aws_api_gateway_integration.api, aws_api_gateway_method.api]
  rest_api_id = aws_api_gateway_rest_api.api.id

  # Lifecycle hooks required to gracefully redeploy if the integration resource changes
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_integration.api))
  }
}

resource "aws_api_gateway_method_settings" "api-gateway_settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_account" "api_gateway_settings" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

# IAM follows the principle of least privilege.
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "cloudwatch" {
  name = "${var.region}_${var.environment}_api_gateway_cloudwatch"

  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}