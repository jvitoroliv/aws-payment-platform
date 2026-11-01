# main.tf
# Part of the primary resource definitions module.

/*====
 ALB for SupportTool
======*/


resource "aws_security_group" "supporttool" {
  name        = format("%s-supportTool-sg", var.environment)
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port = "443"
    to_port   = "443"
    protocol  = "TCP"
    self      = true
  }

  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "TCP"
    self      = true
  }

  egress {
    from_port = "443"
    to_port   = "443"
    protocol  = "TCP"
    self      = "true"
  }

  egress {
    from_port = "80"
    to_port   = "80"
    protocol  = "TCP"
    self      = "true"
  }

  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "TCP"
    self      = true
  }

  egress {
    from_port = 3000
    to_port   = 3000
    protocol  = "TCP"
    self      = true
  }

  tags = {
    Environment = var.environment
  }
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "alb" {
  source              = "./alb"
  environment         = var.environment
  vpc_id              = var.vpc_id
  security_groups_ids = [aws_security_group.supporttool.id]
  subnets_ids         = var.subnets_ids
  public_subnet_ids   = var.public_subnet_ids
  alb_ssl_cert_arn    = var.alb_ssl_cert_arn
}

/*====
Cloudwatch Log Group
======*/
resource "aws_cloudwatch_log_group" "openjobs" {
  name = format("openjobs-%s-%s", var.environment, var.region)

  tags = {
    Environment = var.environment
    Application = "OpenJobs"
  }
}

/*====
ECS cluster
======*/
resource "aws_ecs_cluster" "cluster" {
  name = format("%s-supportTool-ecs-cluster", var.environment)
}

/*====
ECS task definitions
======*/

/* the task definition for the api service */
data "template_file" "api_task" {
  template = file("${path.module}/tasks/api_task_definition.json")

  vars = {
    image          = var.image_name
    container_name = "api"
    log_group      = aws_cloudwatch_log_group.openjobs.name
    region         = var.region
    cpu            = 1024
    memory         = 2048
    environment    = var.environment
    dd_api_key     = var.dd_api_key
    datadog_image  = var.datadog_image
  }
}

# Task definition is versioned — each deployment creates a new revision.
resource "aws_ecs_task_definition" "api" {
  family                   = format("%s_api", var.environment)
  container_definitions    = data.template_file.api_task.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn

  tags = {
    Environment = var.environment
  }

}

/*=============
IAM service role
==============*/
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com", "ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = format("ecs_role-%s", var.region)
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role.json
}

/* ecs service scheduler role */
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = file("${path.module}/policies/ecs-service-role.json")
  role   = aws_iam_role.ecs_role.id
}

/* role that the Amazon ECS container agent and the Docker daemon can assume */
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role-${var.region}"
  assume_role_policy = file("${path.module}/policies/ecs-task-execution-role.json")
}
# IAM follows the principle of least privilege.
resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = file("${path.module}/policies/ecs-execution-role-policy.json")
  role   = aws_iam_role.ecs_execution_role.id
}

/*======
ECS service
======*/

/* Security Group for ECS */
resource "aws_security_group" "ecs_service" {
  vpc_id      = var.vpc_id
  name        = format("%s-ecs-service-sg", var.environment)
  description = "Allow egress from container"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = format("%s-ecs-service-sg", var.environment)
    Environment = var.environment
  }
}

# Spread placement across AZs ensures fault tolerance.
resource "aws_ecs_service" "api" {
  name            = format("%s-api", var.environment)
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.cluster.id

  network_configuration {
    security_groups = flatten([aws_security_group.supporttool.id, aws_security_group.ecs_service.id])
    subnets         = flatten([var.subnets_ids])
  }

  load_balancer {
    target_group_arn = module.alb.alb_target_group_arn
    container_name   = "api"
    container_port   = "3000"
  }
  depends_on = [module.alb]
}

resource "aws_route53_record" "api" {
  zone_id = var.hosted_zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = false
  }
}

/*====
Auto Scaling for ECS
======*/

resource "aws_iam_role" "ecs_autoscale_role" {
  name               = format("%s_ecs_autoscale_role-%s", var.environment, var.region)
  assume_role_policy = file("${path.module}/policies/ecs-autoscale-role.json")
}
resource "aws_iam_role_policy" "ecs_autoscale_role_policy" {
  name   = "ecs_autoscale_role_policy"
  policy = file("${path.module}/policies/ecs-autoscale-role-policy.json")
  role   = aws_iam_role.ecs_autoscale_role.id
}

resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs_autoscale_role.arn
  min_capacity       = 2
  max_capacity       = 4
}

resource "aws_appautoscaling_policy" "up" {
  name               = format("%s_scale_up", var.environment)
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"


  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_appautoscaling_policy" "down" {
  name               = format("%s_scale_down", var.environment)
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

/* metric used for auto scale */
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = format("%s_openjobs_api_cpu_utilization_high", var.environment)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "85"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.api.name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
  ok_actions    = [aws_appautoscaling_policy.down.arn]
}
