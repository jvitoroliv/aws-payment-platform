# main.tf
# Part of the primary resource definitions module.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "common-api-service" {
  source                           = "../ecs-fargate/service"
  api_discovery_endpoint           = ""
  artifactory_secret_arn           = var.artifactory_secret_arn
  aws_region                       = var.aws_region
  cluster_name                     = var.cluster_name
  datadog_log_group                = var.datadog_log_group
  dd_api_key                       = var.dd_api_key
  dd_tag_cardinality               = var.dd_tag_cardinality
  mock_version                    = var.mock_version
  environment                      = var.environment
  flags                            = "-environment ${var.environment} -region ${var.aws_region} -chronos-url ${var.chronos_url}"
  job_image                        = var.job_image
  job_name                         = var.job_name
  log_lambda_arn                   = var.log_lambda_arn
  log_script_filter                = var.log_script_filter
  tagcore_instance_region_role_arn = aws_iam_role.ecs_common_api_instance_region_role.arn
  container_port                   = 8002
  host_port                        = 8002
  crowdstrike-cid                  = var.crowdstrike-cid
}

# desired_count is managed by auto-scaling; Terraform ignores drift.
resource "aws_ecs_service" "tagcore-service" {
  name            = format("%s-%s", var.job_name, var.environment)
  cluster         = var.cluster_id
  task_definition = module.common-api-service.task_name
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = module.common-api-lb-primary.alb_tg_arns[0]
    container_name   = var.job_name
    container_port   = 8002
  }

  load_balancer {
    target_group_arn = module.common-api-lb-internal.alb_tg_arns[0]
    container_name   = var.job_name
    container_port   = 8002
  }


  network_configuration {
    security_groups  = [aws_security_group.common-api.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }
}

resource "aws_security_group" "common-api" {
  name   = format("ecs-common-api-fargate-%s", var.environment)
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8000
    to_port   = 8002
    protocol  = "tcp"
    security_groups = concat(
      [for sg in aws_security_group.common_api_lb_https : sg.id],
      [for sg in aws_security_group.common_api_internal_lb_https : sg.id],
      var.common_api_alb_security_groups,
      var.common_api_internal_alb_security_groups
    )
  }
}
