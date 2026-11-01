# load-balancers-internal.tf
# Part of the load-balancers-internal Terraform configuration module.

resource "aws_lb" "payments_scheduler_api_internal_lb" {
  access_logs {
    bucket  = var.shared_access_log_bucket
    enabled = true
    prefix  = "payments-scheduler-api-${var.environment}-${var.aws_region}-internal-alb-access-logs"
  }
  enable_cross_zone_load_balancing = true
  idle_timeout                     = var.load_balancer_idle_timeout
  internal                         = true
  name                             = format("payments-scheduler-%s", var.environment)
  subnets                          = var.aws_private_subnet_ids

  security_groups = concat(
    [aws_security_group.payments_scheduler_api_internal_lb_https.id],
    var.additional_alb_security_groups
  )

  tags = {
    Service = var.app_id
  }
  timeouts {
    create = "30m"
    delete = "30m"
  }
}

resource "aws_lb_target_group" "payments_scheduler_api_internal_lb_tg" {
  name        = format("payments-scheduler-tg-%s", var.environment)
  count       = length(var.listener_targets)
  depends_on  = [aws_lb.payments_scheduler_api_internal_lb]
  port        = var.listener_targets[count.index]["be_port"]
  protocol    = var.listener_targets[count.index]["be_proto"]
  target_type = "ip"
  vpc_id      = var.aws_vpc_id
  dynamic "health_check" {
    for_each = [lookup(var.listener_targets[count.index], "health_check", {})]
    content {
      enabled             = lookup(health_check.value, "enabled", var.health_check_enabled)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", var.health_check_healthy_threshold)
      interval            = lookup(health_check.value, "interval", var.health_check_interval)
      matcher             = lookup(health_check.value, "matcher", var.health_check_matcher)
      path                = lookup(health_check.value, "path", var.health_check_path)
      port                = lookup(health_check.value, "port", var.health_check_port)
      protocol            = lookup(health_check.value, "protocol", var.listener_targets[count.index]["be_proto"])
      timeout             = lookup(health_check.value, "timeout", var.health_check_timeout)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", var.health_check_unhealthy_threshold)
    }
  }
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "payments_scheduler_api_internal_lb_listener" {
  certificate_arn   = var.listener_targets[count.index]["lb_proto"] == "HTTPS" ? var.web_ssl_cert_arn : null
  count             = length(var.listener_targets)
  load_balancer_arn = aws_lb.payments_scheduler_api_internal_lb.arn
  port              = var.listener_targets[count.index]["lb_port"]
  protocol          = var.listener_targets[count.index]["lb_proto"]
  ssl_policy        = var.listener_targets[count.index]["lb_ssl_policy"]
  default_action {
    target_group_arn = aws_lb_target_group.payments_scheduler_api_internal_lb_tg[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "payments_scheduler_api_internal_lb_redirect_listener" {
  load_balancer_arn = aws_lb.payments_scheduler_api_internal_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
# Security Groups
resource "aws_security_group" "payments_scheduler_api_internal_lb_https" {
  name        = format("payments-scheduler-api-%s-%s-internal-https-lb-sg", var.environment, var.aws_region)
  description = format("first load balancer https sg for env:%s", var.environment)
  vpc_id      = var.aws_vpc_id

  egress {
    cidr_blocks = [var.internal_cidr_block]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  lifecycle { create_before_destroy = true }
}



# Security Group Rules
# Least-privilege: only the ports required by the service are open.
resource "aws_security_group_rule" "payments_scheduler_api_internal_ingress_rule_https" {
  cidr_blocks       = var.api_internal_whitelist
  count             = length(local.ingress_rules_https)
  description       = local.ingress_rules_https[count.index][3]
  from_port         = local.ingress_rules_https[count.index][0]
  protocol          = local.ingress_rules_https[count.index][2]
  security_group_id = aws_security_group.payments_scheduler_api_internal_lb_https.id
  to_port           = local.ingress_rules_https[count.index][1]
  type              = "ingress"
}
