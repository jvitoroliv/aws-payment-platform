# locals.tf
# Manages local value computations resources.

locals {
  internal_cidr = data.aws_vpc.current.cidr_block
  ingress_rules_https = {
    from_port   = 443,
    to_port     = 443,
    protocol    = "tcp",
    description = "LB can be reached by this",
  }

  internal_ingress_rules_https = {
    from_port   = 443,
    to_port     = 443,
    protocol    = "tcp",
    description = "LB can be reached by this",
  }

  max_ingress_rules                    = 120
  common_api_allowlist_chunks          = chunklist(var.common_api_whitelist, local.max_ingress_rules)
  common_api_internal_allowlist_chunks = chunklist(var.common_api_internal_whitelist, local.max_ingress_rules)
}