# tag-alb.tf
# Manages load balancer configuration resources.

# Application Load Balancer
resource "aws_lb" "lb" {
  access_logs {
    bucket  = var.shared_access_log_bucket
    enabled = true
    prefix  = "tag-core-${var.environment}-${var.region}-alb-access-logs"
  }
  enable_cross_zone_load_balancing = true
  idle_timeout                     = var.idle_timeout
  internal                         = var.internal
  name                             = var.lb_name
  security_groups                  = var.security_groups
  subnets                          = var.subnet_ids
  tags = {
    Service = var.name
  }
  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# Target Groups
# Thresholds tuned based on observed startup time in production.
resource "aws_lb_target_group" "tg" {
  name        = format("fgate-%s-%s", var.name, var.environment)
  count       = length(var.listener_targets)
  depends_on  = [aws_lb.lb]
  port        = var.listener_targets[count.index]["be_port"]
  protocol    = var.listener_targets[count.index]["be_proto"]
  target_type = "ip"
  vpc_id      = var.vpc_id

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

# Listeners
resource "aws_lb_listener" "lb_listener" {
  certificate_arn   = var.listener_targets[count.index]["lb_proto"] == "HTTPS" ? var.ssl_cert_arn : null
  count             = length(var.listener_targets)
  load_balancer_arn = aws_lb.lb.arn
  port              = var.listener_targets[count.index]["lb_port"]
  protocol          = var.listener_targets[count.index]["lb_proto"]
  ssl_policy        = var.listener_targets[count.index]["lb_proto"] == "HTTPS" ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : null
  default_action {
    target_group_arn = aws_lb_target_group.tg[count.index].arn
    type             = "forward"
  }
}