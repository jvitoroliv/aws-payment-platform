# locals.tf
# Manages local value computations resources.

locals {
  ingress_rules_https = {
    from_port   = 443,
    to_port     = 443,
    protocol    = "tcp",
    description = "LB can be reached by this",
  }
  max_ingress_rules             = 120
  internal_cidr                 = data.aws_vpc.current.cidr_block
  api_allowlist_chunks          = chunklist(var.api_whitelist, local.max_ingress_rules)
  api_internal_allowlist_chunks = chunklist(var.api_internal_whitelist, local.max_ingress_rules)
}
