# alb.tf
# Part of the load balancer configuration module.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "aws_alb" {
  source  = "terraform-aws-modules/alb/aws//wrappers"
  version = "9.9.0"

  defaults = var.load_balancer_defaults
  items    = var.load_balancers
}