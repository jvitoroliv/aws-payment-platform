# locals.tf
# Part of the local value computations module.

locals {
  ingress_rules_https = {
    from_port   = 443,
    to_port     = 443,
    protocol    = "tcp",
    description = "LB can be reached by this",
  }
  internal_cidr                 = data.aws_vpc.current.cidr_block
  max_ingress_rules             = 120
  web_allowlist_chunks          = chunklist(var.web_whitelist, local.max_ingress_rules)
  web_internal_allowlist_chunks = chunklist(var.web_internal_whitelist, local.max_ingress_rules)
}
