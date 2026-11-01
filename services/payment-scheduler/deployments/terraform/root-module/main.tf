# main.tf
# Part of the primary resource definitions module.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "allowlist" {
  source = "../modules/tag-allowlist"
  allowlists = jsondecode(
  file("${path.module}/../configuration/allowlists/${var.environment}.json"))
  cidrs_blocks_by_name = jsondecode(
  file("${path.module}/../configuration/allowlists/cidrs_blocks_by_name.json"))

}

module "payments_ecs" {
  source = "../modules/ecs"
  additional_alb_security_groups = flatten([
    for allowlist in var.ingress_allowlists :
    lookup(data.terraform_remote_state.shared.outputs.allowlist_security_group_ids_by_allowlist_name, allowlist)
  ])
  artifactory_secret_arn     = data.aws_secretsmanager_secret.artifactory.arn
  api_internal_fqdns_name    = format("payments-internal-%s-%s.platform.example.%s", var.environment, var.aws_region, var.environment == "prod" ? "com" : "net")
  api_internal_whitelist     = module.allowlist.api_internal_allowlist_cidr_blocks
  app_id                     = "payments"
  autoscaling_max_capacity   = var.autoscaling_max_capacity
  autoscaling_min_capacity   = var.autoscaling_min_capacity
  aws_account_id             = data.aws_caller_identity.current.account_id
  aws_private_subnet_ids     = var.aws_private_subnet_ids
  aws_region                 = var.aws_region
  aws_vpc_id                 = var.aws_vpc_id
  container_image            = "registry.example.io/tag-docker-${var.environment == "prod" ? "prod" : "nonprod"}-federated-us/tag/payment-scheduler-api:${var.app_version}"
  crowdstrike_sensor_version = "7.17.0-5602.container.x86_64.Release.US-1"
  datadog_api_key            = local.datadog_api_key.datadog-api-key
  dns_zone_id                = var.dns_zone_id
  environment                = var.environment
  internal_cidr_block        = data.aws_vpc.current.cidr_block
  listener_targets           = [{ lb_port = 443, lb_proto = "HTTPS", be_port = 8001, be_proto = "HTTP", lb_ssl_policy = var.load_balancer_ssl_policy }, ]
  log_lambda_arn             = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  shared_access_log_bucket   = data.terraform_remote_state.shared.outputs.access_log_bucket_name
  task_definition_cpu        = var.task_definition_cpu
  task_definition_memory     = var.task_definition_memory
  vpc_cidr_bridge            = data.aws_vpc.current.cidr_block
  web_ssl_cert_arn           = var.web_ssl_cert_arn
  endpoint_security_cid            = data.aws_ssm_parameter.endpoint_security_cid.value
  container_port             = 8001
}
