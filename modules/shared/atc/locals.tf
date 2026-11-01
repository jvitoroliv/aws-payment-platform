# locals.tf
# Manages local value computations resources.

locals {
  region_weights = {
    "us-east-1" = var.active_region == "us-east-1" ? 100 : 0
    "us-west-2" = var.active_region == "us-west-2" ? 100 : 0
  }
}
