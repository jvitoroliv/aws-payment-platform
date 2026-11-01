# cluster.tf
# Manages cluster Terraform configuration resources.

resource "aws_ecs_cluster" "payments_scheduler_cluster" {
  name = format("%s-%s-%s", var.environment, var.aws_region, var.app_id)
  tags = {
    NOSCHEDULE = "ECS"
  }
}

