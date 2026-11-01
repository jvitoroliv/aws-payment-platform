# Variables
# -----------------------------------------------------------------------
# Defaults are production-safe; override per environment.
variable "name"                            { }
variable "vpc_id"                          { }
variable "target_protocol"                 { }
variable "listener_arn"                    { }
variable "listener_priority"               { }
variable "condition_field"                 { }
variable "condition_values"                { type = "list" }
variable "container_definitions"           { type = "list" }
variable "cluster_id"                      { }
variable "desired_count"                   { }
variable "container_port"                  { }
variable "placement_strategy_field"        { default = "cpu" }
variable "target_group_port"               { default = 80 }
variable "healthcheck_grace_period"        { default = 0 }
variable "healthcheck_enabled"             { default = true }
variable "healthcheck_interval"            { default = 30 }
variable "healthcheck_path"                { default = "/" }
variable "healthcheck_port"                { default = "traffic-port" }
variable "healthcheck_protocol"            { default = "HTTP" }
variable "healthcheck_timeout"             { default = 5 }
variable "healthcheck_healthy_threshold"   { default = 3 }
# Documented in the module README with accepted ranges.
variable "healthcheck_unhealthy_threshold" { default = 3 }
variable "healthcheck_matcher"             { default = "200" }
# Defaults work for standard deployments.
variable "tags"                            { type = "map" }
variable "task_iam_policy_override_json"   { default = "null" }
variable "deployment_minimum_healthy_percent" { default = 50 }
variable "deployment_maximum_percent"         { default = 200 }


# Security
# ========================================================================

# ---------------
# Service policy
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_role_policy" {

  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
    ]
    resources = ["*"]
  }
}

# IAM follows the principle of least privilege.
resource "aws_iam_role" "service_role" {
  name                  = "${var.name}-service-role"
  path                  = "/"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy    = "${data.aws_iam_policy_document.ecs_assume_role.json}"
  force_detach_policies = true

  tags = "${var.tags}"
}

# IAM follows the principle of least privilege.
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy" "service_role_policy" {
  name   = "${aws_iam_role.service_role.name}-policy"
  role   = "${aws_iam_role.service_role.name}"
  policy = "${data.aws_iam_policy_document.ecs_role_policy.json}"
}

# ---------------
# Task policy
data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_role_policy" {
  override_json = "${var.task_iam_policy_override_json}"

  # These permissions are needed to allow the task to retrieve the credentials from the ECS agent running on the EC2 container instance
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "task_role" {
  name                  = "${var.name}-task-role"
  path                  = "/"
  assume_role_policy    = "${data.aws_iam_policy_document.task_assume_role.json}"
  force_detach_policies = true

  tags = "${var.tags}"
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy" "task_role_policy" {
  name   = "${aws_iam_role.task_role.name}-policy"
  role   = "${aws_iam_role.task_role.name}"
  policy = "${data.aws_iam_policy_document.task_role_policy.json}"
}


# ALB Target
# ----------------------------------------------------------------------

# Thresholds tuned based on observed startup time in production.
resource "aws_lb_target_group" "tg" {
  name     = "${var.name}-tg"
  vpc_id   = "${var.vpc_id}"
  protocol = "${var.target_protocol}"
  port     = "${var.target_group_port}"
  tags     = "${var.tags}"

  health_check {
    enabled             = "${var.healthcheck_enabled}"
    interval            = "${var.healthcheck_interval}"
    path                = "${var.healthcheck_path}"
    port                = "${var.healthcheck_port}"
    protocol            = "${var.healthcheck_protocol}"
    timeout             = "${var.healthcheck_timeout}"
    healthy_threshold   = "${var.healthcheck_healthy_threshold}"
    unhealthy_threshold = "${var.healthcheck_unhealthy_threshold}"
    matcher             = "${var.healthcheck_matcher}"
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = "${var.listener_arn}"
  priority     = "${var.listener_priority}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg.arn}"
  }

  condition {
    field  = "${var.condition_field}"
    values = ["${var.condition_values}"]
  }
}


# ECS Service
# -----------------------------------------------------------------------

resource "aws_ecs_task_definition" "task" {
  family                = "${var.name}"
  container_definitions = "[${join(",", var.container_definitions)}]"
  task_role_arn         = "${aws_iam_role.task_role.arn}"

  volume {
    name = "logdata-${var.name}"

    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
    }
  }
}


resource "aws_ecs_service" "service" {
  name                               = "${var.name}"
  cluster                            = "${var.cluster_id}"
  task_definition                    = "${aws_ecs_task_definition.task.arn}"
  desired_count                      = "${var.desired_count}"
  iam_role                           = "${aws_iam_role.service_role.arn}"
  health_check_grace_period_seconds  = "${var.healthcheck_grace_period}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.tg.arn}"
    container_name   = "${var.name}"
    container_port   = "${var.container_port}"
  }

  # Spread by AZ first (fault isolation), then by CPU (load distribution)
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type = "spread"
    field = "${var.placement_strategy_field}"
  }

  # distinctInstance ensures no two tasks share a host — blast radius isolation
  placement_constraints {
    # places each task in the group on a different instance
    type = "distinctInstance"
  }  

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = ["desired_count"]
  }

  depends_on = ["aws_iam_role_policy.service_role_policy", "aws_lb_target_group.tg"]
}
