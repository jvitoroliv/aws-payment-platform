# task-defs.tf
# Manages task-defs Terraform configuration resources.

# Task definition is versioned — each deployment creates a new revision.
resource "aws_ecs_task_definition" "payments_scheduler_task_definition" {
  family                   = format("%s-%s", var.app_id, var.environment)
  execution_role_arn       = aws_iam_role.payments_scheduler_ecs_api_region_role.arn
  task_role_arn            = aws_iam_role.payments_scheduler_ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_definition_cpu
  memory                   = var.task_definition_memory

  container_definitions = nonsensitive(
    templatefile(
      "${path.module}/task-defs/base.json",
      {
        artifactory_secret_arn     = var.artifactory_secret_arn
        api_discovery_endpoint     = format("%s.%s:8001", aws_service_discovery_private_dns_namespace.payments_scheduler_api_private_dns_namespace.name, aws_service_discovery_service.payments_scheduler_api_discovery_service.name)
        aws_region                 = var.aws_region
        cloudwatch_log_group       = aws_cloudwatch_log_group.payments_scheduler_log_group.name
        container_host_port        = var.container_host_port
        container_image            = var.container_image
        container_port             = var.container_port
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_api_key            = var.datadog_api_key
        datadog_image              = var.datadog_image
        datadog_log_group          = aws_cloudwatch_log_group.datadog.name
        crowdstrike_log_group      = aws_cloudwatch_log_group.crowdstrike_log_group.name
        endpoint_security_cid            = var.endpoint_security_cid
        datadog_tag_cardinality    = var.datadog_tag_cardinality
        environment                = var.environment
        task_name                  = "${var.app_id}-task"
        flags                      = ""
      }
    )
  )

  volume {
    name = "crowdstrike-falcon-volume"

  }
  volume {
    name = "crowdstrike-private-${var.app_id}-task"

  }

  tags = {
    Application = var.app_id
    NOSCHEDULE  = "ECS"
  }
}
