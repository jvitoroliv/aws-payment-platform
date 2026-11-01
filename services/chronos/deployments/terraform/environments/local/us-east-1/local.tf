# local.tf
# Manages local Terraform configuration resources.

# VPC sized to /16 to accommodate future subnet expansion across 4+ AZs
resource "aws_vpc" "mock_vpc" {
  cidr_block = "10.90.188.0/22"
}

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "chronos" {
  source                    = "../../../chronos"
  active_region             = var.active_region
  aging_event_sns_topic_arn = "arn:aws:sns:us-east-1:999999999999:aging-event"
  artifact_bucket           = var.artifact_bucket
  artifact_extension        = ".zip"
  artifact_path             = var.artifact_path
  aws_account_number        = var.aws_account_number
  aws_region                = var.aws_region
  code_version              = "local"
  dd_api_key                = ""
  environment               = var.environment
  logconsumer_lambda_arn    = ""
  mongo_uri                 = var.mongo_uri
  mongo_username            = var.mongo_username
  subnet_ids                = var.subnet_ids
  vpc_cidr                  = aws_vpc.mock_vpc.cidr_block
  vpc_id                    = aws_vpc.mock_vpc.id
  datadog_lambda_layer      = ""
  depends_on = [
    module.mock_aging_topic
  ]
}

module "mock_aging_topic" {
  source     = "../../../infra-modules/sns"
  tags       = {}
  topic_name = "aging-event"
}

module "integration" {
  source                = "../../../integration"
  card-processor_queue        = "arn:aws:sqs:us-east-1:999999999999:local-us-east-1-card-processor"
  statement_queue       = "arn:aws:sqs:us-east-1:999999999999:local-us-east-1-statements"
  topic_arn_cycling     = module.chronos.chronos_billable_entity_cycling_sns_topic_arn
  topic_arn_delinquency = module.chronos.chronos_billable_entity_delinquency_changed_sns_topic_arn
  topic_arn_latefee     = module.chronos.chronos_billable_entity_late_fee_sns_topic_arn
}
