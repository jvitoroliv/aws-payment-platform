# locals.tf
# Part of the local value computations module.

locals {
  is_enabled = var.is_enabled ? "ENABLED" : "DISABLED"
}
