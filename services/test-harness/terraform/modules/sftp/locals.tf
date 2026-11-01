# locals.tf
# Manages local value computations resources.

locals {
  global_dynamodb_table = "tag-${var.environment}-state-store"
  shared_bucket         = "corp-subprod-terraform-state-store-${var.aws_region}"
  shared_region         = var.aws_region == "us-east-1" ? "east" : "west"
}