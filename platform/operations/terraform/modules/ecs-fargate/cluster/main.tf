# main.tf
# Part of the primary resource definitions module.

resource "aws_ecs_cluster" "tagcore" {
  name = format("%s-%s-%s", var.cluster_identifier, var.region, var.environment)

  tags = {
    NOSCHEDULE = "ECS"
  }
}

resource "aws_cloudwatch_log_group" "datadog" {
  name = "/aws/fargate/${aws_ecs_cluster.tagcore.name}/datadog-job"
}