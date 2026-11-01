# main.tf
# Part of the primary resource definitions module.

# Create the IAM role for the lambda
# IAM follows the principle of least privilege.
resource "aws_iam_role" "iam_lambda_role" {
  name                 = "payment-service_lambda_iam_role"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PermissionsBoundaryPolicy"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach policies to the lambda role
resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_secrets_manager_read_write" {
  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_cloudwatch_logs_full_access" {
  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_aws_lambda_vpc_access_execution_role" {
  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_aws_lambda_eni_management_access" {
  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_aws_lambda_full_access" {
  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_aws_sqs_full_access" {
  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_aws_s3_full_access" {
  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create lambda
resource "aws_lambda_function" "lambda_function" {
  function_name = local.long_app_name
  image_uri     = local.lambda_image_uri
  package_type  = "Image"
  timeout       = 180

  role = aws_iam_role.iam_lambda_role.arn

  environment {
    variables = {
      DOTNET_ENVIRONMENT          = local.dotnet_environment[terraform.workspace]
      LAMBDA_DOTNET_MAIN_ASSEMBLY = local.lambda_dotnet_main_assembly

      # Datadog Section
      DD_TRACE_ENABLED               = local.enable_datadog[terraform.workspace]
      DD_APM_ENABLED                 = local.enable_datadog[terraform.workspace]
      DD_SERVERLESS_LOGS_ENABLED     = local.enable_datadog[terraform.workspace]
      DD_API_KEY                     = data.aws_secretsmanager_secret_version.transaction_disputes_datadog.secret_string
      DD_DOGSTATSD_NON_LOCAL_TRAFFIC = "true"
    }
  }

  image_config {
    command = local.lambda_command
  }

  vpc_config {
    security_group_ids = [data.aws_security_group.PaymentServiceTLS.id]
    subnet_ids = data.aws_subnets.private.ids
  }
}
