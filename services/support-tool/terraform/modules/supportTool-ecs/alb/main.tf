# main.tf
# Part of the primary resource definitions module.

/*====
App Load Balancer
======*/
resource "random_id" "target_group_sufix" {
  byte_length = 2
}

resource "aws_alb_target_group" "alb_target_group" {
  name        = "${var.environment}-alb-target-group-${random_id.target_group_sufix.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path     = "/health-check"
    interval = 240
  }
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    create_before_destroy = true
  }
}

/* security group for ALB */
resource "aws_security_group" "api_inbound_sg" {
  name        = "${var.environment}-api-inbound-sg"
  description = "Allow HTTP from Anywhere into ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.internal_cidr]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.internal_cidr]
  }

  tags = {
    Name = "${var.environment}-api-inbound-sg"
  }
}

resource "aws_alb" "alb_openjobs" {
  name            = "${var.environment}-alb-openjobs"
  subnets         = flatten([var.public_subnet_ids])
  security_groups = flatten([var.security_groups_ids, aws_security_group.api_inbound_sg.id])

  tags = {
    Name        = "${var.environment}-alb-openjobs"
    Environment = var.environment
  }
}

resource "aws_alb_listener" "openJobs_redirect_listener" {
  load_balancer_arn = aws_alb.alb_openjobs.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.alb_target_group]

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "openjobsHTTPS" {
  load_balancer_arn = aws_alb.alb_openjobs.arn
  port              = "443"
  protocol          = "HTTPS"
  depends_on        = [aws_alb_target_group.alb_target_group]

  certificate_arn = var.alb_ssl_cert_arn
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"

  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    type             = "forward"
  }
}
