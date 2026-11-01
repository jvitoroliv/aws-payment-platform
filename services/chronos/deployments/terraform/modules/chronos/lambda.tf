# lambda.tf
# Part of the Lambda function definitions module.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "chronos_billable_entity_cycling_lambda" {
  source = "../infra-modules/scheduled-event"

  aws_region            = var.aws_region
  aws_account_number    = var.aws_account_number
  artifact_bucket       = var.artifact_bucket
  artifact_key          = "${var.artifact_path}/billable-entity-cycling${var.artifact_extension}"
  datadog_lambda_layer  = var.datadog_lambda_layer
  function_name         = "chronos-${var.environment}-${var.aws_region}-billable-entity-cycling"
  handler_name          = "main"
  runtime               = "provided.al2"
  environment           = var.environment
  subnet_ids            = var.subnet_ids
  security_group_ids    = [aws_security_group.lambda_egress.id]
  active_region         = var.active_region
  concurrent_executions = var.concurrent_executions
  memsize               = var.memsize
  cron_schedules = {
    "cron(0 6 * * ? *)" = "{\"Action\": \"DailyProcessing\"}"
  }
  scheduled_event_enabled = var.scheduled_event_enabled

  lambda_env_vars = {
    CHRONOS_ENV                = var.environment
    CHRONOS_REGION             = var.aws_region
    CHRONOS_PARAM_STORE_PREFIX = local.key_prefix
    CHRONOS_SNS_TOPIC_PREFIX   = local.sns_topic_prefix
    CHRONOS_SQS_PREFIX         = local.sqs_prefix
    CHRONOS_VERSION            = var.code_version
    DD_SITE                    = "datadoghq.com"
    DD_API_KEY                 = var.dd_api_key
  }

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

# Cycling lambda requires SNS access
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "chronos_cycling_sns_perms" {
  policy_arn = aws_iam_policy.sns_access.arn
  role       = module.chronos_billable_entity_cycling_lambda.execution_role_name
}

resource "aws_cloudwatch_log_group" "billable_entity_cycling_logs" {
  name              = "/aws/lambda/chronos-${var.environment}-${var.aws_region}-billable-entity-cycling"
  retention_in_days = 365
}
resource "aws_cloudwatch_log_subscription_filter" "billable_entity_cycling_logs" {
  count           = var.logconsumer_lambda_arn != "" ? 1 : 0
  name            = "${var.environment}-chronos-billable-entity-cycling-logs"
  log_group_name  = aws_cloudwatch_log_group.billable_entity_cycling_logs.name
  filter_pattern  = ""
  destination_arn = var.logconsumer_lambda_arn
}

module "chronos_aging_event_lambda" {
  source = "../infra-modules/sns-handler"

  aws_account_number    = var.aws_account_number
  aws_region            = var.aws_region
  artifact_bucket       = var.artifact_bucket
  artifact_key          = "${var.artifact_path}/aging-event${var.artifact_extension}"
  datadog_lambda_layer  = var.datadog_lambda_layer
  function_name         = "chronos-${var.environment}-${var.aws_region}-aging-event"
  handler_name          = "main"
  runtime               = "provided.al2"
  sns_topic_arn         = var.aging_event_sns_topic_arn
  environment           = var.environment
  subnet_ids            = var.subnet_ids
  security_group_ids    = [aws_security_group.lambda_egress.id]
  concurrent_executions = var.concurrent_executions
  memsize               = var.memsize

  lambda_env_vars = {
    CHRONOS_ENV                = var.environment
    CHRONOS_REGION             = var.aws_region
    CHRONOS_PARAM_STORE_PREFIX = local.key_prefix
    CHRONOS_SNS_TOPIC_PREFIX   = local.sns_topic_prefix
    CHRONOS_SQS_PREFIX         = local.sqs_prefix
    CHRONOS_VERSION            = var.code_version
    DD_SITE                    = "datadoghq.com"
    DD_API_KEY                 = var.dd_api_key
  }

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

# Aging event lambda requires SNS access
resource "aws_iam_role_policy_attachment" "chronos_aging_sns_perms" {
  policy_arn = aws_iam_policy.sns_access.arn
  role       = module.chronos_aging_event_lambda.execution_role_name
}

resource "aws_cloudwatch_log_group" "aging_event_logs" {
  name              = "/aws/lambda/chronos-${var.environment}-${var.aws_region}-aging-event"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_subscription_filter" "aging_event_logs" {
  count           = var.logconsumer_lambda_arn != "" ? 1 : 0
  name            = "${var.environment}-chronos-aging-event-logs"
  log_group_name  = aws_cloudwatch_log_group.aging_event_logs.name
  filter_pattern  = ""
  destination_arn = var.logconsumer_lambda_arn
}

module "chronos_api" {
  source = "../infra-modules/api"

  artifact_bucket       = var.artifact_bucket
  artifact_key          = "${var.artifact_path}/api${var.artifact_extension}"
  aws_account_number    = var.aws_account_number
  concurrent_executions = var.concurrent_executions
  datadog_lambda_layer  = var.datadog_lambda_layer
  environment           = var.environment
  function_name         = "chronos-${var.environment}-${var.aws_region}-api"
  handler_name          = "main"
  region                = var.aws_region
  runtime               = "provided.al2"
  security_group_ids    = [aws_security_group.lambda_egress.id]
  subnet_ids            = var.subnet_ids
  vpc_whitelist         = var.vpc_id

  lambda_env_vars = {
    CHRONOS_ENV                = var.environment
    CHRONOS_REGION             = var.aws_region
    CHRONOS_PARAM_STORE_PREFIX = local.key_prefix
    CHRONOS_SNS_TOPIC_PREFIX   = local.sns_topic_prefix
    CHRONOS_VERSION            = var.code_version
    DD_SITE                    = "datadoghq.com"
    DD_API_KEY                 = var.dd_api_key
  }

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/lambda/chronos-${var.environment}-${var.aws_region}-api"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_subscription_filter" "api_logs" {
  count           = var.logconsumer_lambda_arn != "" ? 1 : 0
  name            = "${var.environment}-chronos-api-logs"
  log_group_name  = aws_cloudwatch_log_group.api_logs.name
  filter_pattern  = ""
  destination_arn = var.logconsumer_lambda_arn
}

resource "aws_security_group" "lambda_egress" {
  name        = "chronos-${var.environment}-${var.aws_region}-lambda-egress"
  description = "Managed by Terraform"
  vpc_id      = var.vpc_id
  ingress {
    cidr_blocks = [var.vpc_cidr]
    description = "local vpc ingress"
    from_port   = 1025
    protocol    = "tcp"
    to_port     = 1025
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "mongo"
    from_port   = 27017
    protocol    = "tcp"
    to_port     = 27017
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSM"
    from_port   = 2121
    protocol    = "tcp"
    to_port     = 2121
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS"
    from_port   = 53
    protocol    = "tcp"
    to_port     = 53
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS"
    from_port   = 53
    protocol    = "udp"
    to_port     = 53
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "TLS Auth"
    from_port   = 465
    protocol    = "tcp"
    to_port     = 465
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "sftp mastercard"
    from_port   = 16022
    protocol    = "tcp"
    to_port     = 16022
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "sentential"
    from_port   = 2222
    protocol    = "tcp"
    to_port     = 2222
  }
  egress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
