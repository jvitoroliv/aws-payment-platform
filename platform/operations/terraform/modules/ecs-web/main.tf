# main.tf
# Manages primary resource definitions resources.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "tagcore-web" {
  source                           = "../ecs-fargate/service"
  api_discovery_endpoint           = format("%s.%s:8001", aws_service_discovery_private_dns_namespace.web-api.name, aws_service_discovery_service.web-api.name)
  artifactory_secret_arn           = var.artifactory_secret_arn
  aws_region                       = var.aws_region
  cluster_name                     = var.cluster_name
  container_port                   = 8000
  datadog_log_group                = var.datadog_log_group
  dd_api_key                       = var.dd_api_key
  dd_tag_cardinality               = var.dd_tag_cardinality
  mock_version                    = var.mock_version
  environment                      = var.environment
  flags                            = "-environment ${var.environment} -staticResourceDir /web -region ${var.aws_region}"
  host_port                        = 8000
  job_image                        = var.job_image
  job_name                         = var.job_name
  log_lambda_arn                   = var.log_lambda_arn
  log_script_filter                = var.log_script_filter
  tagcore_instance_region_role_arn = aws_iam_role.ecs_web_instance_region_role.arn
  crowdstrike-cid                  = var.crowdstrike-cid

  // putting this here reflecting that the namespace is prebuilt for both api and web
  depends_on = [
    aws_service_discovery_private_dns_namespace.web-api,
    aws_service_discovery_service.web-api
  ]
}

# Spread placement across AZs ensures fault tolerance.
resource "aws_ecs_service" "tagcore-service" {
  name            = format("%s-%s", var.job_name, var.environment)
  cluster         = var.cluster_id
  task_definition = module.tagcore-web.task_name
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = module.web-lb.alb_tg_arns[0]
    container_name   = var.job_name
    container_port   = 8000
  }
  load_balancer {
    target_group_arn = module.web-lb-internal.alb_tg_arns[0]
    container_name   = var.job_name
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.web.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }
}

resource "aws_service_discovery_private_dns_namespace" "web-api" {
  name = format("ecs-web-api-%s-%s", var.aws_region, var.environment)
  vpc  = var.aws_vpc_id
}

resource "aws_service_discovery_service" "web-api" {
  name = format("ecs-web-api-%s-%s", var.aws_region, var.environment)
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.web-api.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

output "service_disc_arn" {
  value = aws_service_discovery_service.web-api.arn
}

output "service_disc_fq_endpoint" {
  value = format("%s.%s:8001", aws_service_discovery_private_dns_namespace.web-api.name, aws_service_discovery_service.web-api.name)
}

resource "aws_security_group" "web" {
  name   = format("web-gate-%s", var.environment)
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
    from_port   = 8000
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //TODO: This would seem to need to change
  }
  ingress {
    from_port = 8000
    to_port   = 8001
    protocol  = "tcp"
    security_groups = concat(
      [for sg in aws_security_group.web_lb_https : sg.id],
      [for sg in aws_security_group.web_int_lb_https : sg.id],
      var.web_alb_security_groups,
      var.web_internal_alb_security_groups
    )
  }
}
