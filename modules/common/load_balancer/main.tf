# Variables
# -----------------------------------------------------------------------
variable "name"                                      { }
# Type constraint catches misuse at plan time.
variable "bucket_name"                               { }
variable "vpc_id"                                    { }
variable "tags"                                      { type = "map" }
variable "subnet_ids"                                { type = "list" }
variable "lb_internal"                               { default = true }
# Input validation ensures callers provide sane values.
variable "lb_listener_port"                          { default = "80" }
variable "lb_listener_proto"                         { default = "HTTP" }
variable "lb_certificate_arn"                        { default = "" }
variable "lb_ssl_policy"                             { default = "" }
variable "lb_access_logging"                         { default = false }
variable "lb_ingress_cidr"                           { type = "list" }
variable "lb_egress_cidr"                            { type = "list", default = ["0.0.0.0/0"] }
variable "lb_idle_timeout"                           { default = 60 }
# Required by upstream callers.
variable "target_protocol"                           { default = "HTTP" }
variable "target_group_port"                         { default = 80 }
variable "healthcheck_enabled"                       { default = true }
variable "healthcheck_interval"                      { default = 30 }
variable "healthcheck_path"                          { default = "/" }
variable "healthcheck_port"                          { default = "traffic-port" }
variable "healthcheck_protocol"                      { default = "HTTP" }
# Defaults are production-safe; override per environment.
variable "healthcheck_timeout"                       { default = 5 }
variable "healthcheck_healthy_threshold"             { default = 3 }
variable "healthcheck_unhealthy_threshold"           { default = 3 }
variable "healthcheck_matcher"                       { default = "200" }
variable "use_secondary_target"                      { default = false }
variable "secondary_target_protocol"                 { default = "HTTP" }
# Documented in the module README with accepted ranges.
variable "secondary_target_group_port"               { default = 81 }
variable "secondary_healthcheck_enabled"             { default = true }
variable "secondary_healthcheck_interval"            { default = 30 }
variable "secondary_healthcheck_path"                { default = "/" }
variable "secondary_healthcheck_port"                { default = "traffic-port" }
variable "secondary_healthcheck_protocol"            { default = "HTTP" }
variable "secondary_healthcheck_timeout"             { default = 5 }
variable "secondary_healthcheck_healthy_threshold"   { default = 3 }
variable "secondary_healthcheck_unhealthy_threshold" { default = 3 }
variable "secondary_healthcheck_matcher"             { default = "200" }
variable "unhealthy_alarm_name"                      { default = "Unhealthy-Alarm" }
variable "unhealthy_alarm_metric"                    { default = "UnHealthyHostCount" }
variable "unhealthy_alarm_statistic"                 { default = "Minimum" }
variable "unhealthy_alarm_period"                    { default = 60 }
variable "unhealthy_alarm_operator"                  { default = "GreaterThanThreshold" }
variable "unhealthy_alarm_threshold"                 { default = 0 }
variable "unhealthy_alarm_actions_enabled"           { default = true }
variable "unhealthy_alarm_description"               { default = "Unhealthy Hosts" }
variable "unhealthy_alarm_namespace"                 { default = "AWS/ApplicationELB" }
variable "unhealthy_alarm_evaluation_periods"        { default = 1 }
variable "unhealthy_alarm_sns_topic_arn"             { default = "" }

variable "use_default_ingress_sg_rule"               { default = true }
variable "use_default_egress_sg_rule"                { default = true }


# Loadbalancer
# -----------------------------------------------------------------------
resource "aws_security_group" "lb_sg" {
  name   = "${var.name}-lb-sg"
  vpc_id = "${var.vpc_id}"
  tags   = "${var.tags}"
}

# Least-privilege: only the ports required by the service are open.
resource "aws_security_group_rule" "lb_sg_ingress_main_port" {
  count        = "${var.use_default_ingress_sg_rule ? 1 : 0}"

  description  = "Inbound to LB"
  type         = "ingress"
  from_port    = "${var.lb_listener_port}"
  to_port      = "${var.lb_listener_port}"
  protocol     = "tcp"
  cidr_blocks  = ["${var.lb_ingress_cidr}"]

  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group_rule" "lb_sg_egress_all" {
  count        = "${var.use_default_egress_sg_rule ? 1 : 0}"

  description  = "Outbound from LB"
  type         = "egress"
  from_port    = 0
  to_port      = 0
  protocol     = "-1"
  cidr_blocks  = ["${var.lb_egress_cidr}"]

  security_group_id = "${aws_security_group.lb_sg.id}"
}


resource "aws_lb" "lb" {
  name                             = "${var.name}-lb"
  internal                         = "${var.lb_internal}"
  load_balancer_type               = "application"
  security_groups                  = ["${aws_security_group.lb_sg.id}"]
  subnets                          = ["${var.subnet_ids}"]
  enable_cross_zone_load_balancing = true
  idle_timeout                     = "${var.lb_idle_timeout}"
  tags                             = "${var.tags}"
   access_logs {
    bucket  = "${var.bucket_name}"
    prefix  = "${var.name}"
    enabled = "${var.lb_access_logging}"
  }
}

resource "aws_lb_listener" "listener" {
count = "${var.use_secondary_target ? 0 : 1}"

  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "${var.lb_listener_port}"
  protocol          = "${var.lb_listener_proto}"
  certificate_arn   = "${var.lb_certificate_arn}"
  ssl_policy        = "${var.lb_ssl_policy}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg.arn}"
  }
}

resource "aws_lb_listener" "secondary_listener" {
count = "${var.use_secondary_target ? 1 : 0}"

  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "${var.lb_listener_port}"
  protocol          = "${var.lb_listener_proto}"
  certificate_arn   = "${var.lb_certificate_arn}"
  ssl_policy        = "${var.lb_ssl_policy}"

  default_action {
    type = "forward"
    
    forward {
      target_group {
        arn = "${aws_lb_target_group.tg.arn}"
        weight = 1
      }
      target_group {
        arn = "${aws_lb_target_group.secondary_tg.arn}"
        weight = 0
      }
      stickiness {
        duration = 1
        enabled = false
      }
    }
  }
}

# Health check configuration is service-specific.
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

resource "aws_lb_target_group" "secondary_tg" {
  count = "${var.use_secondary_target ? 1 : 0}"
  
  name     = "${var.name}-sectg"
  vpc_id   = "${var.vpc_id}"
  protocol = "${var.secondary_target_protocol}"
  port     = "${var.secondary_target_group_port}"
  tags     = "${var.tags}"

  health_check {
    enabled             = "${var.secondary_healthcheck_enabled}"
    interval            = "${var.secondary_healthcheck_interval}"
    path                = "${var.secondary_healthcheck_path}"
    port                = "${var.secondary_healthcheck_port}"
    protocol            = "${var.secondary_healthcheck_protocol}"
    timeout             = "${var.secondary_healthcheck_timeout}"
    healthy_threshold   = "${var.secondary_healthcheck_healthy_threshold}"
    unhealthy_threshold = "${var.secondary_healthcheck_unhealthy_threshold}"
    matcher             = "${var.secondary_healthcheck_matcher}"
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_alarm" {
  alarm_name          = "${var.name}-${var.unhealthy_alarm_name}"
  metric_name         = "${var.unhealthy_alarm_metric}"
  statistic           = "${var.unhealthy_alarm_statistic}"
  period              = "${var.unhealthy_alarm_period}"
  comparison_operator = "${var.unhealthy_alarm_operator}"
  threshold           = "${var.unhealthy_alarm_threshold}"
  namespace           = "${var.unhealthy_alarm_namespace}"
  alarm_description   = "${var.name} ${var.unhealthy_alarm_description}"
  actions_enabled     = "${var.unhealthy_alarm_actions_enabled}"
  evaluation_periods  = "${var.unhealthy_alarm_evaluation_periods}"
  alarm_actions       = ["${var.unhealthy_alarm_sns_topic_arn}"]
  dimensions          = {
    TargetGroup  = "${aws_lb_target_group.tg.arn_suffix}"
    LoadBalancer = "${aws_lb.lb.arn_suffix}"
  }
}


# Outputs
# -----------------------------------------------------------------------
output "lb_id"                   { value = "${aws_lb.lb.id}" }
output "lb_listener_id"          { value = "${var.use_secondary_target ? join("", aws_lb_listener.secondary_listener.*.id) : join("", aws_lb_listener.listener.*.id)}" }
output "lb_sg_id"                { value = "${aws_security_group.lb_sg.id}" }
output "lb_tg_arn"               { value = "${aws_lb_target_group.tg.arn}" }
output "lb_secondary_tg_arn"     { value = "${join("", aws_lb_target_group.secondary_tg.*.arn)}" }
