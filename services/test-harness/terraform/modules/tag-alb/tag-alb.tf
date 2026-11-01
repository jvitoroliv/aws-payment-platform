# tag-alb.tf
# Part of the load balancer configuration module.

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group" "lb_http" {
  name        = format("%s_%s_REMOVE_http_lb_sg_MOCK", var.environment, var.name)
  vpc_id      = var.vpc_id
  description = format("load balancer sg for http for env:%s lb:%s", var.environment, var.name)
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle { create_before_destroy = true }
}

# Least-privilege: only the ports required by the service are open.
resource "aws_security_group" "lb_https" {
  name        = format("%s_%s_https_lb_sg_MOCK", var.environment, var.name)
  vpc_id      = var.vpc_id
  description = format("load balancer sg for https for env:%s lb:%s", var.environment, var.name)
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "ingress_rules_http" {
  count = length(var.ingress_rules_http)

  security_group_id = aws_security_group.lb_http.id
  type              = "ingress"
  cidr_blocks       = var.ingress_whitelist

  from_port   = var.ingress_rules_http[count.index][0]
  to_port     = var.ingress_rules_http[count.index][1]
  protocol    = var.ingress_rules_http[count.index][2]
  description = var.ingress_rules_http[count.index][3]
}

resource "aws_security_group_rule" "egress_rules_http" {
  count = length(var.egress_rules)

  security_group_id = aws_security_group.lb_http.id
  type              = "egress"
  cidr_blocks       = var.egress_whitelist

  from_port   = var.egress_rules[count.index][0]
  to_port     = var.egress_rules[count.index][1]
  protocol    = var.egress_rules[count.index][2]
  description = var.egress_rules[count.index][3]
}

resource "aws_security_group_rule" "ingress_rules_https" {
  count = length(var.ingress_rules_https)

  security_group_id = aws_security_group.lb_https.id
  type              = "ingress"
  cidr_blocks       = var.ingress_whitelist

  from_port   = var.ingress_rules_https[count.index][0]
  to_port     = var.ingress_rules_https[count.index][1]
  protocol    = var.ingress_rules_https[count.index][2]
  description = var.ingress_rules_https[count.index][3]
}

resource "aws_lb" "lb" {
  name                             = format("fargate-alb-%s-%s-MOCK", var.name, var.environment)
  subnets                          = var.subnet_ids
  security_groups                  = [aws_security_group.lb_http.id, aws_security_group.lb_https.id]
  internal                         = false
  enable_cross_zone_load_balancing = true
  idle_timeout                     = var.idle_timeout
  timeouts {
    create = "30m"
    delete = "30m"
  }

  tags = {
    Service = var.name
  }
}

//TODO: To be deleted
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.testharness_arn
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn = var.web_ssl_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = var.mock_coreplatform_arn
  }
}

resource "aws_lb_listener_rule" "test_harness_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = var.testharness_arn
  }

  condition {
    host_header {
      values = ["testharness-${var.aws_region}-${var.environment}.*"]
    }
  }
}

resource "aws_lb_listener_rule" "mock_chronos_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = var.mock_chronos_arn
  }

  condition {
    path_pattern {
      values = ["/mock-chronos/*"]
    }
  }
}

resource "aws_route53_record" "dns_name" {
  zone_id = var.dns_zone_id
  name    = "mock-${var.aws_region}-${var.environment}.platform.example.com"
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
  }
}

resource "aws_route53_record" "mock_dns_name" {
  zone_id = var.dns_zone_id
  name    = "testharness-${var.aws_region}-${var.environment}.platform.example.com"
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
  }
}
