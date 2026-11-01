# service.tf
# Part of the service Terraform configuration module.

# desired_count is managed by auto-scaling; Terraform ignores drift.
resource "aws_ecs_service" "payments_scheduler_service" {
  name            = format("%s-%s", var.environment, var.app_id)
  cluster         = aws_ecs_cluster.payments_scheduler_cluster.id
  task_definition = aws_ecs_task_definition.payments_scheduler_task_definition.arn
  desired_count   = var.autoscaling_min_capacity
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.payments_scheduler_api_internal_lb_tg[0].arn
    container_name   = "${var.app_id}-task"
    container_port   = 8001
  }

  network_configuration {
    security_groups  = [aws_security_group.payments_scheduler_api_service_security_group.id]
    subnets          = var.aws_private_subnet_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.payments_scheduler_api_discovery_service.arn
  }

  tags = {
    NOSCHEDULE = "ECS"
  }
}

#ecs service security group.
resource "aws_security_group" "payments_scheduler_api_service_security_group" {
  name   = format("payments-scheduler-api-service-security-group-%s", var.environment)
  vpc_id = var.aws_vpc_id
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.internal_cidr_block]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //TODO: This would seem to need to change
  }
  egress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [aws_security_group.payments_scheduler_api_internal_lb_https.id]
    cidr_blocks     = [var.vpc_cidr_bridge]
  }
}