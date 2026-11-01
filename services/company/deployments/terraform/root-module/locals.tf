# locals.tf
# Manages local value computations resources.

locals {
  # Configuration variables
  is_subprod      = var.environment == "dev" || var.environment == "test"
  nonprod_or_prod = var.environment != "prod" ? "nonprod" : "prod"
  subprod_or_prod = local.is_subprod ? "subprod" : "prod"
  shared_bucket   = "${local.is_subprod ? "" : "new-"}finservtag-${local.subprod_or_prod}-terraform-state-store-${var.region}"
  shared_region   = var.region == "us-east-1" ? "east" : "west"
  state_key       = "shared-${local.shared_region}-${var.environment}.tfstate"
}
