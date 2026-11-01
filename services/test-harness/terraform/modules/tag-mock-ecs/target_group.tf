# target_group.tf
# Part of the target_group Terraform configuration module.

# Health check configuration is service-specific.
# Thresholds tuned based on observed startup time in production.
resource "aws_lb_target_group" "th" {
  name        = format("test-harness-%s-MOCK", var.environment)
  port        = 6660
  protocol    = "HTTP"
  vpc_id      = var.aws_vpc_id
  target_type = "ip"

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "coreplatform" {
  name        = format("mock-coreplatform-%s-MOCK", var.environment)
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.aws_vpc_id
  target_type = "ip"

  # Lifecycle rules prevent Terraform from reverting auto-scaler changes.
  lifecycle {
    create_before_destroy = true
  }
}

# Health check configuration is service-specific.
resource "aws_lb_target_group" "chronos" {
  name        = format("mock-chronos-%s-MOCK", var.environment)
  port        = 9096
  protocol    = "HTTP"
  vpc_id      = var.aws_vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}
