# api-alb.tf
# Manages load balancer configuration resources.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "api-lb" {
  source                   = "../tag-alb"
  environment              = var.environment
  internal                 = false
  lb_name                  = format("ecs-fgate-alb-api-%s", var.environment)
  name                     = "ecs-api"
  region                   = var.aws_region
  security_groups          = concat([for sg in aws_security_group.api_lb_https : sg.id], var.api_alb_security_groups)
  shared_access_log_bucket = var.shared_access_log_bucket
  ssl_cert_arn             = var.public_ssl_cert_arn
  subnet_ids               = var.public_subnet_ids
  vpc_id                   = var.aws_vpc_id
  listener_targets         = [{ lb_port = 443, lb_proto = "HTTPS", be_port = 8001, be_proto = "HTTP" }]

}

# Security Groups
resource "aws_security_group" "api_lb_https" {
  count       = length(local.api_allowlist_chunks)
  name        = format("%s_%s_%s_https_lb_%s", "ecs-api", var.environment, var.aws_region, count.index)
  description = format("load balancer sg %s for https for env:%s lb:%s", count.index, var.environment, "api")
  vpc_id      = var.aws_vpc_id

  egress {
    cidr_blocks = [local.internal_cidr]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "api_lb_ingress_https" {
  count             = length(local.api_allowlist_chunks)
  cidr_blocks       = local.api_allowlist_chunks[count.index]
  description       = local.ingress_rules_https["description"]
  from_port         = local.ingress_rules_https["from_port"]
  protocol          = local.ingress_rules_https["protocol"]
  security_group_id = aws_security_group.api_lb_https[count.index].id
  to_port           = local.ingress_rules_https["to_port"]
  type              = "ingress"
}

# Apex DNS
resource "aws_route53_record" "apex_api_dns_name" {
  allow_overwrite = true
  zone_id         = var.dns_zone
  name            = var.api_fqdns_name
  type            = "A"

  alias {
    evaluate_target_health = false
    name                   = format("%v", module.api-lb.alb_dns_name)
    zone_id                = format("%v", module.api-lb.alb_zone_id)
  }

  depends_on = [module.api-lb]
}