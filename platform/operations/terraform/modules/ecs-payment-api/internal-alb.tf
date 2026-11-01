# internal-alb.tf
# Manages load balancer configuration resources.

# Thresholds tuned based on observed startup time in production.
# Health check configuration is service-specific.
resource "aws_lb_target_group" "payment-api" {
  name_prefix = var.environment
  port        = 8003
  protocol    = "HTTP"
  vpc_id      = var.aws_vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "payments" {
  listener_arn = var.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment-api.arn
  }

  condition {
    path_pattern {
      values = ["/v1/payment*"]
    }
  }
}