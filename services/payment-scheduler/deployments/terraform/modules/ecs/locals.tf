# locals.tf
# Manages local value computations resources.

locals {
  ingress_rules_https = [
    # [from_port, to_port, protocol, description]
    [443, 443, "tcp", "LB can be reached by this"],
  ]
}