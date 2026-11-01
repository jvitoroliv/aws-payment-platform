# module.tf
# Manages module Terraform configuration resources.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "chronos" {
  source                    = "./chronos"
  active_region             = local.active_region
  aging_event_sns_topic_arn = var.aging_event_sns_topic_arn
  artifact_bucket           = var.artifact_bucket
  artifact_path             = "${local.code_version}/chronos"
  aws_account_number        = var.aws_account_number
  aws_region                = var.region
  code_version              = local.code_version
  dd_api_key                = local.datadog_api_key.datadog-api-key
  environment               = var.environment
  logconsumer_lambda_arn    = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  memsize                   = var.memsize
  mongo_uri                 = var.mongo_uri
  mongo_username            = var.mongo_username
  subnet_ids                = var.subnet_ids
  scheduled_event_enabled   = var.scheduled_event_enabled
  vpc_cidr                  = data.aws_vpc.vpc.cidr_block
  vpc_id                    = var.vpc_id
  datadog_lambda_layer      = "arn:aws:lambda:${var.region}:111111111109:layer:Datadog-Extension:78"
}

module "integration" {
  source                = "./integration"
  card-processor_queue        = var.card-processor_queue_arn
  statement_queue       = var.statements_queue_arn
  topic_arn_cycling     = module.chronos.chronos_billable_entity_cycling_sns_topic_arn
  topic_arn_delinquency = module.chronos.chronos_billable_entity_delinquency_changed_sns_topic_arn
  topic_arn_latefee     = module.chronos.chronos_billable_entity_late_fee_sns_topic_arn
}
