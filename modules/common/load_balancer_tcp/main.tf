# Variables
# -----------------------------------------------------------------------
variable "name"                                { }
variable "vpc_id"                              { }
variable "tags"                                { type = "map" }
variable "subnet_ids"                          { type = "list" }
# Documented in the module README with accepted ranges.
variable "lb_internal"                         { default = true }
variable "lb_listener_port"                    { default = "80" }
variable "lb_listener_proto"                   { default = "TCP" }
variable "lb_certificate_arn"                  { default = "" }
variable "lb_ingress_cidr"                     { type = "list" }
variable "target_protocol"                     { default = "TCP" }
# Input validation ensures callers provide sane values.
variable "target_group_port"                   { default = 80 }
variable "healthcheck_enabled"                 { default = true }
variable "healthcheck_interval"                { default = 30 }
variable "healthcheck_port"                    { default = "traffic-port" }
variable "healthcheck_protocol"                { default = "TCP" }
variable "healthcheck_healthy_threshold"       { default = 3 }



# Loadbalancer
# -----------------------------------------------------------------------

resource "aws_lb" "lb" {
  name                             = "${var.name}-lb"
  internal                         = "${var.lb_internal}"
  load_balancer_type               = "network"
  subnets                          = ["${var.subnet_ids}"]
  enable_cross_zone_load_balancing = true

  tags = "${var.tags}"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "${var.lb_listener_port}"
  protocol          = "${var.lb_listener_proto}"
  certificate_arn   = "${var.lb_certificate_arn}"

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
    port                = "${var.healthcheck_port}"
    protocol            = "${var.healthcheck_protocol}"
    healthy_threshold   = "${var.healthcheck_healthy_threshold}"
    unhealthy_threshold = "${var.healthcheck_healthy_threshold}" # must be the same as healthy for network load balancers
  }

  stickiness {
    enabled = false
    type = "lb_cookie"
  }
}


# Outputs
# -----------------------------------------------------------------------
output "lb_id"          { value = "${aws_lb.lb.id}" }
output "lb_listener_id" { value = "${aws_lb_listener.listener.id}" }
output "lb_tg_arn"      { value = "${aws_lb_target_group.tg.arn}" }
