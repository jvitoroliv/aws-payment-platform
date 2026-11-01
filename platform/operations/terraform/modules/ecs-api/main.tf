# main.tf
# Manages primary resource definitions resources.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "tagcore-api" {
  source                           = "../ecs-fargate/service"
  api_discovery_endpoint           = ""
  artifactory_secret_arn           = var.artifactory_secret_arn
  aws_region                       = var.aws_region
  cluster_name                     = var.cluster_name
  container_port                   = 8001
  datadog_log_group                = var.datadog_log_group
  dd_api_key                       = var.dd_api_key
  dd_tag_cardinality               = var.dd_tag_cardinality
  mock_version                    = var.mock_version
  environment                      = var.environment
  flags                            = "-environment ${var.environment} -region ${var.aws_region} -chronos-url ${var.chronos_url}"
  host_port                        = 8001
  job_image                        = var.job_image
  job_name                         = var.job_name
  log_lambda_arn                   = var.log_lambda_arn
  log_script_filter                = var.log_script_filter
  tagcore_instance_region_role_arn = aws_iam_role.api_instance_region_role.arn
  task_cpu                         = var.api_cpu
  task_memory                      = var.api_memory
  crowdstrike-cid                  = var.crowdstrike-cid
}

resource "aws_ecs_service" "tagcore-service" {
  name            = format("%s-%s", var.job_name, var.environment)
  cluster         = var.cluster_id
  task_definition = module.tagcore-api.task_name
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = module.api-lb.alb_tg_arns[0]
    container_name   = var.job_name
    container_port   = 8001
  }

  load_balancer {
    target_group_arn = module.api-lb-internal.alb_tg_arns[0]
    container_name   = var.job_name
    container_port   = 8001
  }

  service_registries {
    registry_arn = var.registry_arn
  }


  network_configuration {
    security_groups  = [aws_security_group.api.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }
}

resource "aws_security_group" "api" {
  name   = format("web-api-sg-fgate-%s", var.environment)
  vpc_id = var.aws_vpc_id
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [local.internal_cidr]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //TODO: This would seem to need to change
  }
  egress {
    from_port   = 6348
    to_port     = 6348
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //TODO: I have no idea what this port is used for
  }
  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow outbound traffic to the Aiven Schema Registry"
    from_port   = var.aiven_schema_registry_port
    to_port     = var.aiven_schema_registry_port
    protocol    = "tcp"
    cidr_blocks = [var.core_services_cidr]
  }
  ingress {
    from_port = 8000
    to_port   = 8001
    protocol  = "tcp"
    security_groups = concat(
      [for sg in aws_security_group.api_lb_https : sg.id],
      [for sg in aws_security_group.api_int_lb_https : sg.id],
      var.api_alb_security_groups,
      var.api_internal_alb_security_groups
    )
    cidr_blocks = [var.vpc_cidr_bridge]
  }

}