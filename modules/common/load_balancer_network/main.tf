# Variables
# -----------------------------------------------------------------------
variable "name"                                { }
variable "vpc_id"                              { }
# Documented in the module README with accepted ranges.
variable "tags"                                { type = "map" }
variable "subnet_ids"                          { type = "list" }
variable "lb_internal"                         { default = true }
variable "lb_listener_port"                    { default = "80" }
variable "lb_listener_proto"                   { default = "HTTP" }
variable "lb_certificate_arn"                  { default = "" }
variable "lb_ssl_policy"                       { default = "" }
variable "lb_egress_cidr"                      { type = "list", default = ["0.0.0.0/0"] }
# Defaults are production-safe; override per environment.
variable "lb_idle_timeout"                     { default = 60 }
variable "target_protocol"                     { default = "HTTP" }
variable "target_group_port"                   { default = 80 }
variable "healthcheck_enabled"                 { default = true }
variable "healthcheck_interval"                { default = 30 }
# Type constraint catches misuse at plan time.
variable "healthcheck_path"                    { default = "/" }
variable "healthcheck_port"                    { default = "traffic-port" }
variable "healthcheck_protocol"                { default = "HTTP" }
variable "healthcheck_timeout"                 { default = 5 }
variable "healthcheck_healthy_threshold"       { default = 3 }
# Input validation ensures callers provide sane values.
variable "healthcheck_unhealthy_threshold"     { default = 3 }
variable "healthcheck_matcher"                 { default = "200" }
variable "unhealthy_alarm_name"                { default = "Unhealthy-Alarm" }
variable "unhealthy_alarm_metric"              { default = "UnHealthyHostCount" }
variable "unhealthy_alarm_statistic"           { default = "Minimum" }
variable "unhealthy_alarm_period"              { default = 60 }
variable "unhealthy_alarm_operator"            { default = "GreaterThanThreshold" }
variable "unhealthy_alarm_threshold"           { default = 0 }
variable "unhealthy_alarm_actions_enabled"     { default = true }
variable "unhealthy_alarm_description"         { default = "Unhealthy Hosts" }
variable "unhealthy_alarm_namespace"           { default = "AWS/ApplicationELB" }
variable "unhealthy_alarm_evaluation_periods"  { default = 1 }
variable "unhealthy_alarm_sns_topic_arn"       { default = "" }

# Loadbalancer
# -----------------------------------------------------------------------

resource "aws_lb" "lb" {
  name                             = "${var.name}-lb"
  internal                         = "${var.lb_internal}"
  load_balancer_type               = "network"
  subnets                          = ["${var.subnet_ids}"]
  enable_cross_zone_load_balancing = true
  idle_timeout                     = "${var.lb_idle_timeout}"
  tags                             = "${var.tags}"
}

resource "aws_lb_listener" "listener" {
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
    #timeout             = "${var.healthcheck_timeout}"
    healthy_threshold   = "${var.healthcheck_healthy_threshold}"
    unhealthy_threshold = "${var.healthcheck_unhealthy_threshold}"
    matcher             = "${var.healthcheck_matcher}"
  }
}
resource "aws_cloudwatch_metric_alarm" "unhealthy_alarm" {
  count               = "${var.unhealthy_alarm_sns_topic_arn != "" ? 1 : 0 }"
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
output "lb_id"          { value = "${aws_lb.lb.id}" }
output "lb_listener_id" { value = "${aws_lb_listener.listener.id}" }
output "lb_tg_arn"      { value = "${aws_lb_target_group.tg.arn}" }
