# main.tf
# Manages primary resource definitions resources.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "job-service" {
  source                 = "../../ecs-fargate/service"
  api_discovery_endpoint = ""
  artifactory_secret_arn = var.artifactory_secret_arn
  prepend                = "job-"
  aws_region             = var.aws_region
  cluster_name           = var.cluster_name
  datadog_log_group      = var.datadog_log_group
  dd_api_key             = var.dd_api_key
  environment            = var.environment
  mock_version          = var.mock_version
  flags = format("-environment %s -region %s %s",
    var.environment,
    var.aws_region,
    var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
  )
  job_image                        = var.job_image
  job_name                         = var.job_name
  log_lambda_arn                   = var.log_lambda_arn
  log_script_filter                = var.log_script_filter
  tagcore_instance_region_role_arn = var.iam_role
  container_port                   = 1025
  host_port                        = 1025
  dd_tag_cardinality               = var.dd_tag_cardinality
  crowdstrike-cid                  = var.crowdstrike-cid
}

resource "aws_ecs_service" "tagcore-service" {
  name            = format("%s-%s", var.job_name, var.environment)
  cluster         = var.cluster_id
  task_definition = module.job-service.task_name
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"


  network_configuration {
    security_groups  = [var.sec_group]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}

module "service_scaling" {
  source        = "../../ecs-scaling/ecs-queue-scaling"
  cluster_name  = var.cluster_name
  name          = var.job_name
  environment   = var.environment
  queue_name    = var.queue_name
  service_name  = aws_ecs_service.tagcore-service.name
  max_threshold = var.max_threshold
  min_threshold = var.min_threshold
  max_capacity  = var.max_capacity
  min_capacity  = var.min_capacity
}
