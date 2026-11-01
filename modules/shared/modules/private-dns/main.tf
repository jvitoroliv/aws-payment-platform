# main.tf
# Part of the primary resource definitions module.

resource "aws_route53_zone" "tag_private" {
  name = format("%s-%s", var.environment, var.domain)

  vpc {
    vpc_id = var.vpc_id
  }

  force_destroy = false

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    create_before_destroy = true
  }
}