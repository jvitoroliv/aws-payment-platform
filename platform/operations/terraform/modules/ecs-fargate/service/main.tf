# main.tf
# Part of the primary resource definitions module.

resource "aws_ecs_task_definition" "tagcore" {
  family                   = format("%s-%s", var.job_name, var.environment)
  execution_role_arn       = var.tagcore_instance_region_role_arn
  task_role_arn            = var.tagcore_instance_region_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  # nonsensitive() is used so that container def changes are still visible for review in plan output
  container_definitions = nonsensitive(
    templatefile(
      "${path.module}/task-defs/base.json",
      {
        api_discovery_endpoint     = var.api_discovery_endpoint
        artifactory_secret_arn     = var.artifactory_secret_arn
        aws_logs_group             = aws_cloudwatch_log_group.tagcore.name
        container_port             = var.container_port
        crowdstrike_logs_group     = aws_cloudwatch_log_group.crowdstrikelogs.name
        crowdstrike-cid            = var.crowdstrike-cid
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        datadog_logs_group         = var.datadog_log_group
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        environment                = var.environment
        flags                      = var.flags
        host_port                  = var.host_port
        job_image                  = var.job_image
        job_name                   = "${var.prepend}${var.job_name}"
        region                     = var.aws_region
        tag_cardinality            = var.dd_tag_cardinality
      }
    )
  )

  volume {
    name = "crowdstrike-falcon-volume"

  }

  volume {
    name = format("crowdstrike-private-%s%s", var.prepend, var.job_name)

  }

  tags = {
    NOSCHEDULE = "ECS"
  }

}

resource "aws_cloudwatch_log_group" "tagcore" {
  name = format("/aws/fargate/%s/%s", var.cluster_name, var.job_name)
}

resource "aws_cloudwatch_log_group" "crowdstrikelogs" {


  name = format("/aws/fargate/%s/crowdstrike/%s", var.cluster_name, var.job_name)
}

resource "aws_cloudwatch_log_subscription_filter" "tagcore" {
  count           = var.log_script_filter
  name            = var.job_name
  log_group_name  = aws_cloudwatch_log_group.tagcore.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}
