# main.tf
# Part of the primary resource definitions module.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "payment-api-service" {
  source                           = "../ecs-fargate/service"
  api_discovery_endpoint           = ""
  artifactory_secret_arn           = var.artifactory_secret_arn
  aws_region                       = var.aws_region
  cluster_name                     = var.cluster_name
  container_port                   = 8003
  datadog_log_group                = var.datadog_log_group
  dd_api_key                       = var.dd_api_key
  dd_tag_cardinality               = var.dd_tag_cardinality
  mock_version                    = var.mock_version
  environment                      = var.environment
  flags                            = "-environment ${var.environment} -region ${var.aws_region}"
  host_port                        = 8003
  job_image                        = var.job_image
  job_name                         = var.job_name
  log_lambda_arn                   = var.log_lambda_arn
  log_script_filter                = var.log_script_filter
  tagcore_instance_region_role_arn = aws_iam_role.payment_api_instance_region_role.arn
  task_cpu                         = var.api_cpu
  task_memory                      = var.api_memory
  crowdstrike-cid                  = var.crowdstrike-cid
}

# desired_count is managed by auto-scaling; Terraform ignores drift.
resource "aws_ecs_service" "tagcore-service" {
  name            = format("%s-%s", var.job_name, var.environment)
  cluster         = var.cluster_id
  task_definition = module.payment-api-service.task_name
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"

  // only route from internal load balancer
  load_balancer {
    target_group_arn = aws_lb_target_group.payment-api.arn
    container_name   = var.job_name
    container_port   = 8003
  }

  service_registries {
    registry_arn = var.registry_arn
  }

  network_configuration {
    security_groups  = [aws_security_group.payment-api.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }
}

resource "aws_security_group" "payment-api" {
  name        = format("%s-payment-api", var.environment)
  description = format("Security group for the %s service", var.job_name)
  vpc_id      = var.aws_vpc_id
}

resource "aws_vpc_security_group_egress_rule" "dns_egress" {
  description = "Allow outbound internal DNS traffic"

  security_group_id = aws_security_group.payment-api.id
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = data.aws_vpc.current.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "https_egress" {
  description = "Allow all outbound HTTPS traffic"

  security_group_id = aws_security_group.payment-api.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "mongodb_egress" {
  description = "Allow all outbound MongoDB traffic"

  security_group_id = aws_security_group.payment-api.id
  from_port         = 27017
  to_port           = 27017
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "int_alb_ingress" {
  for_each = toset(var.alb_security_groups)

  description = "Allow inbound traffic from Internal API ALB Security Groups"

  security_group_id            = aws_security_group.payment-api.id
  from_port                    = 8003
  to_port                      = 8003
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value
}
