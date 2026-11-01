# tag-core.tf
# Manages tag-core Terraform configuration resources.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "allowlist" {
  source = "../modules/tag-allowlist"
  allowlists = jsondecode(
  file("${path.module}/../configuration/allowlists/${var.environment}.json"))
  cidrs_blocks_by_name = jsondecode(
  file("${path.module}/../configuration/allowlists/cidrs_blocks_by_name.json"))
}

module "s3" {
  source             = "../modules/tag-s3"
  aws_region         = var.aws_region
  environment        = var.environment
  aws_account_number = var.aws_account_number
  image_url          = var.base_url
}

module "job-service" {
  source                     = "../modules/tag-job-ecs"
  aiven_schema_registry_port = var.aiven_schema_registry_port
  artifactory_secret_arn     = data.aws_secretsmanager_secret.artifactory.arn
  aws_region                 = var.aws_region
  aws_vpc_id                 = var.aws_vpc_id
  chronos_url                = local.chronos_api
  core_services_cidr         = var.core_services_cidr
  dd_api_key                 = local.datadog_api_key.datadog-api-key
  crowdstrike-cid            = local.endpoint_security_cid
  dd_tag_cardinality         = var.dd_tag_cardinality
  desired_count              = var.job_count // 2
  finserv_job_desired_count      = var.finserv_job_count
  job_card_migration_count   = var.job_card_migration_count
  job_coreplatform_count        = var.job_coreplatform_count
  job_file_arrival_count     = var.job_file_arrival_count
  job_mastercard_count       = var.job_mastercard_count
  environment                = var.environment
  mock_version              = local.mock_version
  job_card-processor_image         = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-card-processor:${local.mock_version}"
  job_partner_image              = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-partner:${local.mock_version}"
  job_coreplatform_image        = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-coreplatform:${local.mock_version}"
  job_file_arrival_image     = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-file-arrival:${local.mock_version}"
  job_mail_image             = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-mail:${local.mock_version}"
  job_mastercard_image       = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-mastercard:${local.mock_version}"
  job_scheduled_event_image  = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-scheduled-event:${local.mock_version}"
  job_statements_image       = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-statements:${local.mock_version}"
  job_visa_image             = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-visa:${local.mock_version}"
  job_finserv_image              = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-finserv:${local.mock_version}"
  log_lambda_arn             = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  subnet_ids                 = var.aws_private_subnets
  job_partner_a_coreplatform_image   = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-partner_a-coreplatform:${local.mock_version}"
  job_partner_a_fi_image          = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-partner_a-fi:${local.mock_version}"
  job_partner_fi_image           = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-partner-fi:${local.mock_version}"
  job_card_migration_image   = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-card-migration:${local.mock_version}"
}

module "aws_sftp" {
  count = var.create_sftp_module ? 1 : 0

  source              = "../modules/aws-transfer-sftp"
  vpc_id              = var.aws_vpc_id
  vpc_endpoint_id     = var.sftp_vpc_endpoint_id
  client_network      = [var.dc2_network]
  environment         = var.environment
  s3bucket            = "${var.environment}-${var.aws_region}-app-artifacts-app"
  internal-users      = var.internal_sftp_users
  internal-publickeys = var.internal_sftp_publickeys
  allowed_cidrs       = var.sftp_endpoint_cidrs
  region              = var.aws_region
}

module "sqs" {
  source                        = "../modules/tag-sqs"
  aws_region                    = var.aws_region
  environment                   = var.environment
  aws_account_number            = var.aws_account_number
  app_file_storage              = "${var.environment}-${var.aws_region}-app-artifacts-app"
  create_s3_bucket_notification = var.create_s3_bucket_notification
}

module "email" {
  source                  = "../modules/tag-email"
  environment             = var.environment
  aws_region              = var.aws_region
  email_domain            = var.email_domain
  incoming_mail_bucket_id = module.s3.incoming_mail_storage
  email_bounce_queue_arn  = module.sqs.email_bounce_queue_arn
}

module "cloudwatch" {
  source                    = "../modules/tag-cloudwatch"
  environment               = var.environment
  aws_region                = var.aws_region
  monthly_cron              = "cron(0 16 1 * ? *)"
  scheduled_event_queue_arn = module.sqs.scheduled_event_queue_arn
  is_enabled                = var.aws_region == local.active_region
  quarterly_cron            = "cron(0 17 1 JAN,APR,JULY,OCT ? *)"
}

module "company_update_sns_topic" {
  source     = "../modules/tag-sns"
  topic_name = "${var.environment}-${var.aws_region}-company-update"
  tags = {
    Environment = var.environment
  }
}

module "aging_event_sns_topic" {
  source     = "../modules/tag-sns"
  topic_name = "${var.environment}-${var.aws_region}-aging-event"
  tags = {
    Environment = var.environment
  }
}


// New Stoofs

module "tagcore-cluster" {
  source             = "../modules/ecs-fargate/cluster"
  environment        = var.environment
  region             = var.aws_region
  cluster_identifier = "tagcore"
}

// Services with no tasks
module "tagcore-ecs-job" {
  count                        = 0
  source                       = "../modules/ecs-job"
  arap_image                   = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-card-processor:${local.mock_version}"
  arap_max                     = 0 //6
  arap_max_threshold           = "100"
  arap_min                     = 0 //1
  arap_min_threshold           = "95"
  arap_name                    = "card-processor"
  arap_queue_name              = module.sqs.card-processor_q_name
  artifactory_secret_arn       = data.aws_secretsmanager_secret.artifactory.arn
  aws_region                   = var.aws_region
  aws_vpc_id                   = var.aws_vpc_id
  chronos_url                  = local.chronos_api
  cluster_id                   = module.tagcore-cluster.cluster_id
  cluster_name                 = module.tagcore-cluster.cluster_name
  dd_api_key                   = local.datadog_api_key.datadog-api-key
  dd_tag_cardinality           = var.dd_tag_cardinality
  dd_log_group_name            = module.tagcore-cluster.dd_log_group_name
  mock_version                = local.mock_version
  coreplatform_image              = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-coreplatform:${local.mock_version}"
  coreplatform_max                = 0 //8
  coreplatform_max_threshold      = "400"
  coreplatform_min                = 0 //2
  coreplatform_min_threshold      = "390"
  coreplatform_name               = "coreplatform"
  coreplatform_queue_name         = module.sqs.coreplatform_q_name
  environment                  = var.environment
  file-arrival_image           = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-file-arrival:${local.mock_version}"
  file-arrival_max             = 0 //2
  file-arrival_min             = 0 //1
  file-arrival_name            = "file-arrival"
  file-arrival_queue_name      = module.sqs.file_q_name
  filearr_max_threshold        = 0
  filearr_min_threshold        = 0
  partner_a_coreplatform_image         = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-partner_a-coreplatform:${local.mock_version}"
  partner_a_coreplatform_max           = 0 //6
  partner_a_coreplatform_max_threshold = "350"
  partner_a_coreplatform_min           = 0 //2
  partner_a_coreplatform_min_threshold = "340"
  partner_a_coreplatform_name          = "partner_a-coreplatform"
  partner_a_coreplatform_queue         = module.sqs.partner_a_coreplatform_q
  partner_a_fi_image                = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-partner_a-fi:${local.mock_version}"
  partner_a_fi_max                  = 0 //4
  partner_a_fi_max_threshold        = 0
  partner_a_fi_min                  = 0 //1
  partner_a_fi_min_threshold        = 0
  partner_a_fi_name                 = "partner_a-fi"
  partner_a_fi_queue                = module.sqs.partner_a_fi_q
  partner_fi_image                 = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-partner-fi:${local.mock_version}"
  partner_fi_name                  = "partner-fi"
  partner_fi_queue                 = module.sqs.partner_fi_queue_name
  partner_fi_max                   = 0
  partner_fi_min                   = 0
  partner_fi_max_threshold         = 0
  partner_fi_min_threshold         = 0
  log_lambda_arn               = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  mail_image                   = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-mail:${local.mock_version}"
  mail_max                     = 0 //1
  mail_max_threshold           = 0
  mail_min                     = 0 //1
  mail_min_threshold           = 0
  mail_name                    = "mail"
  mail_queue_name              = module.sqs.mail_q_name
  mastercard_image             = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-mastercard:${local.mock_version}"
  mastercard_max               = 0 //4
  mastercard_min               = 0 //2
  mastercard_name              = "mastercard"
  mastercard_queue_name        = module.sqs.mastercard_q_name
  mc_max_threshold             = 0
  mc_min_threshold             = 0
  partner_image                    = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-partner:${local.mock_version}"
  partner_max                      = 0 //4
  partner_max_threshold            = 0
  partner_min                      = 0 //1
  partner_min_threshold            = 0
  partner_name                     = "partner"
  naf_queue_name               = module.sqs.naf_q_name
  priv_subnets                 = var.aws_private_subnets
  schd_max_threshold           = 0
  schd_min_threshold           = 0
  scheduled-event_image        = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-scheduled-event:${local.mock_version}"
  scheduled-event_max          = 0 //2
  scheduled-event_min          = 0 //1
  scheduled-event_name         = "scheduled-event"
  scheduled-event_queue_name   = module.sqs.sched_q_name
  statements_image             = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-statements:${local.mock_version}"
  statements_max               = 0 //6
  statements_max_threshold     = "300"
  statements_min               = 0 //1
  statements_min_threshold     = "250"
  statements_name              = "statements"
  statements_queue_name        = module.sqs.statements_q_name
  visa_image                   = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-visa:${local.mock_version}"
  visa_max                     = 0 //6
  visa_max_threshold           = "100"
  visa_min                     = 0 //1
  visa_min_threshold           = 0
  visa_name                    = "visa"
  visa_queue_name              = module.sqs.visa_q_name
  finserv_image                    = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-job-finserv:${local.mock_version}"
  finserv_max                      = 0 //4
  finserv_max_threshold            = 0 // "2"
  finserv_min                      = 0 //1
  finserv_min_threshold            = 0
  finserv_name                     = "finserv"
  finserv_queue_name               = module.sqs.finserv_q_name
  crowdstrike-cid              = data.aws_ssm_parameter.crowdstrike-cid.value
  card_migration_image         = "registry.us-east-1.apps.example.com/mock-service-job-card-migration:${local.mock_version}"
  card_migration_name          = "card-migration"
  card_migration_queue         = module.sqs.card_migration_queue_name
  card_migration_max           = 0
  card_migration_min           = 0
  card_migration_max_threshold = 0
  card_migration_min_threshold = 0
}

module "tagcore-ecs-common-api" {
  source                 = "../modules/ecs-common-api"
  artifactory_secret_arn = data.aws_secretsmanager_secret.artifactory.arn
  aws_region             = var.aws_region
  aws_vpc_id             = var.aws_vpc_id
  common_api_alb_security_groups = flatten([
    for key in var.ingress_allowlists_common_api_alb :
    lookup(data.terraform_remote_state.shared.outputs.allowlist_security_group_ids_by_allowlist_name, key)
  ])
  common_api_internal_alb_security_groups = flatten([
    for key in var.ingress_allowlists_common_api_internal_alb :
    lookup(data.terraform_remote_state.shared.outputs.allowlist_security_group_ids_by_allowlist_name, key)
  ])
  chronos_url = data.terraform_remote_state.chronos.outputs.api_invoke_url
  common_api_fqdns_name = format("ecs-common-api-%s-%s.%s", var.environment, var.aws_region,
  var.base_url)
  common_api_internal_fqdns_name = format("ecs-common-api-internal-%s-%s.%s", var.environment, var.aws_region,
  var.base_url)
  cluster_id                    = module.tagcore-cluster.cluster_id
  cluster_name                  = module.tagcore-cluster.cluster_name
  common_api_whitelist          = module.allowlist.common_api_allowlist_cidr_blocks
  common_api_internal_whitelist = module.allowlist.common_api_internal_allowlist_cidr_blocks
  datadog_log_group             = module.tagcore-cluster.dd_log_group_name
  dd_api_key                    = local.datadog_api_key.datadog-api-key
  dd_tag_cardinality            = var.dd_tag_cardinality
  internal_ssl_cert_arn         = var.internal_ssl_cert_arn
  mock_version                 = local.mock_version
  dns_zone                      = var.dns_zone_id
  environment                   = var.environment
  job_image                     = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-common-api:${local.mock_version}"
  job_name                      = "common-api"
  log_lambda_arn                = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  log_script_filter             = 1
  min_capacity                  = var.common_api_min_capacity // 2
  private_subnet_ids            = var.aws_private_subnets
  public_ssl_cert_arn           = var.public_ssl_cert_arn
  public_subnet_ids             = var.aws_public_subnets
  shared_access_log_bucket      = data.terraform_remote_state.shared.outputs.access_log_bucket_name
  crowdstrike-cid               = data.aws_ssm_parameter.crowdstrike-cid.value
}

module "tagcore-ecs-web" {
  source                 = "../modules/ecs-web"
  artifactory_secret_arn = data.aws_secretsmanager_secret.artifactory.arn
  aws_region             = var.aws_region
  aws_vpc_id             = var.aws_vpc_id
  web_alb_security_groups = flatten([
    for key in var.ingress_allowlists_web_alb :
    lookup(data.terraform_remote_state.shared.outputs.allowlist_security_group_ids_by_allowlist_name, key)
  ])
  web_internal_alb_security_groups = flatten([
    for key in var.ingress_allowlists_web_internal_alb :
    lookup(data.terraform_remote_state.shared.outputs.allowlist_security_group_ids_by_allowlist_name, key)
  ])
  dd_api_key               = local.datadog_api_key.datadog-api-key
  dd_tag_cardinality       = var.dd_tag_cardinality
  mock_version            = local.mock_version
  dns_zone                 = var.dns_zone_id
  environment              = var.environment
  cluster_id               = module.tagcore-cluster.cluster_id
  cluster_name             = module.tagcore-cluster.cluster_name
  datadog_log_group        = module.tagcore-cluster.dd_log_group_name
  internal_ssl_cert_arn    = var.internal_ssl_cert_arn
  job_image                = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-web:${local.mock_version}"
  job_name                 = "web"
  log_lambda_arn           = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  log_script_filter        = 1
  min_capacity             = var.web_min_capacity // 2
  private_subnet_ids       = var.aws_private_subnets
  public_ssl_cert_arn      = var.public_ssl_cert_arn
  public_subnet_ids        = var.aws_public_subnets
  shared_access_log_bucket = data.terraform_remote_state.shared.outputs.access_log_bucket_name
  web_fqdns_name = format("ecs-fargate-www-%s-%s.%s", var.environment, var.aws_region,
  var.base_url)
  web_internal_fqdns_name = format("ecs-fargate-int-www-%s-%s.%s", var.environment, var.aws_region,
  var.base_url)
  web_whitelist          = module.allowlist.web_allowlist_cidr_blocks
  web_internal_whitelist = module.allowlist.web_internal_allowlist_cidr_blocks
  crowdstrike-cid        = data.aws_ssm_parameter.crowdstrike-cid.value
}

module "tagcore-ecs-api" {
  source                     = "../modules/ecs-api"
  aiven_schema_registry_port = var.aiven_schema_registry_port
  artifactory_secret_arn     = data.aws_secretsmanager_secret.artifactory.arn
  api_cpu                    = var.api_cpu
  api_fqdns_name = format("ecs-fargate-api-%s-%s.%s", var.environment, var.aws_region,
  var.base_url)
  api_internal_fqdns_name = format("ecs-fargate-api-internal-%s-%s.%s", var.environment, var.aws_region,
  var.base_url)
  api_internal_whitelist = module.allowlist.api_internal_allowlist_cidr_blocks
  api_memory             = var.api_memory
  api_whitelist          = module.allowlist.api_allowlist_cidr_blocks
  api_alb_security_groups = flatten([
    for key in var.ingress_allowlists_api_alb :
    lookup(data.terraform_remote_state.shared.outputs.allowlist_security_group_ids_by_allowlist_name, key)
  ])
  api_internal_alb_security_groups = flatten([
    for key in var.ingress_allowlists_api_internal_alb :
    lookup(data.terraform_remote_state.shared.outputs.allowlist_security_group_ids_by_allowlist_name, key)
  ])
  aws_region               = var.aws_region
  aws_vpc_id               = var.aws_vpc_id
  chronos_url              = data.terraform_remote_state.chronos.outputs.api_invoke_url
  core_services_cidr       = var.core_services_cidr
  dd_api_key               = local.datadog_api_key.datadog-api-key
  dd_tag_cardinality       = var.dd_tag_cardinality
  internal_ssl_cert_arn    = var.internal_ssl_cert_arn
  mock_version            = local.mock_version
  dns_zone                 = var.dns_zone_id
  environment              = var.environment
  cluster_id               = module.tagcore-cluster.cluster_id
  cluster_name             = module.tagcore-cluster.cluster_name
  datadog_log_group        = module.tagcore-cluster.dd_log_group_name
  job_image                = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-api:${local.mock_version}"
  job_name                 = "api"
  log_lambda_arn           = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  log_script_filter        = 1
  min_capacity             = var.api_min_capacity // 2
  private_subnet_ids       = var.aws_private_subnets
  public_ssl_cert_arn      = var.public_ssl_cert_arn
  public_subnet_ids        = var.aws_public_subnets
  registry_arn             = module.tagcore-ecs-web.service_disc_arn
  shared_access_log_bucket = data.terraform_remote_state.shared.outputs.access_log_bucket_name
  vpc_cidr_bridge          = data.aws_vpc.current.cidr_block
  crowdstrike-cid          = data.aws_ssm_parameter.crowdstrike-cid.value
}

module "tagcore-ecs-payment-api" {
  source                 = "../modules/ecs-payment-api"
  alb_listener_arn       = module.tagcore-ecs-api.internal_alb_listener_arns[0]
  alb_security_groups    = module.tagcore-ecs-api.internal_alb_security_groups
  artifactory_secret_arn = data.aws_secretsmanager_secret.artifactory.arn
  api_cpu                = var.api_cpu
  api_memory             = var.api_memory
  aws_region             = var.aws_region
  aws_vpc_id             = var.aws_vpc_id
  dd_api_key             = local.datadog_api_key.datadog-api-key
  dd_tag_cardinality     = var.dd_tag_cardinality
  mock_version          = local.mock_version
  environment            = var.environment
  cluster_id             = module.tagcore-cluster.cluster_id
  cluster_name           = module.tagcore-cluster.cluster_name
  datadog_log_group      = module.tagcore-cluster.dd_log_group_name
  job_image              = "registry.example.io/tag-docker-${local.nonprod_or_prod}-virtual-us/tag/mock-service-payment-api:${local.mock_version}"
  job_name               = "payment-api"
  log_lambda_arn         = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  log_script_filter      = 1
  min_capacity           = var.payment_api_min_capacity // 2
  private_subnet_ids     = var.aws_private_subnets
  registry_arn           = module.tagcore-ecs-web.service_disc_arn
  crowdstrike-cid        = data.aws_ssm_parameter.crowdstrike-cid.value
}
