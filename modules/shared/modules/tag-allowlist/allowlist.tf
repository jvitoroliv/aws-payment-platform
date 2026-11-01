# allowlist.tf
# Manages allowlist Terraform configuration resources.

locals {
  # Generate all rules
  all_rules = {
    for sg_key, sg_value in var.allowlists : sg_key => flatten([
      for rule in sg_value.rules : [
        for source in rule.sources :
          lookup(var.cidrs_blocks_by_name, source, null) != null ? [
            # CIDR rules
            for block in var.cidrs_blocks_by_name[source] : {
              description                  = source
              from_port                    = rule.from_port
              to_port                      = rule.to_port
              protocol                     = rule.protocol
              cidr_ipv4                    = block
              prefix_list_id               = null
              referenced_security_group_id = null
              type                         = "cidr"
            }
          ] : (
            lookup(var.prefix_lists_by_name, source, null) != null ? [
              # Prefix List rules
              for prefix_list_name, prefix_list_id in var.prefix_lists_by_name[source] : {
                description                  = source
                from_port                    = rule.from_port
                to_port                      = rule.to_port
                protocol                     = rule.protocol
                cidr_ipv4                    = null
                prefix_list_id               = prefix_list_id
                referenced_security_group_id = null
                type                         = "prefix_list"
              }
              if prefix_list_name == var.region
            ] : tobool("Error: Source '${source}' not found in either cidrs_blocks_by_name or prefix_lists_by_name maps")
          )
      ]
    ])
  }

  # Separate CIDR and Prefix List rule lists for different chunking strategies
  cidr_rules = {
    for sg_key, rules in local.all_rules : sg_key => [
      for rule in rules : rule if rule.type != "prefix_list"
    ]
  }

  prefix_list_rules = {
    for sg_key, rules in local.all_rules : sg_key => [
      for rule in rules : rule if rule.type == "prefix_list"
    ]
  }

  # CIDR rules chunked using chunklist() seeing as they all have a size of 1
  cidr_chunks = {
    for sg_key, rules in local.cidr_rules : sg_key => (
      length(rules) == 0 ? [] : chunklist(rules, var.max_rules_per_security_group)
    )
  }

  # Prefix list rules vary in size, add one per security group for now
  prefix_list_chunks = {
    for sg_key, rules in local.prefix_list_rules : sg_key => (
      length(rules) == 0 ? [] : [for rule in rules : [rule]]
    )
  }

  # Concat the different chunk types
  # Prefix Lists chunks last so they dont affect CIDR rules if they change
  chunked_security_groups = {
    for sg_key in keys(var.allowlists) : sg_key => {
      description = var.allowlists[sg_key].description
      chunks = concat(
        concat(
          local.cidr_chunks[sg_key],
          local.prefix_list_chunks[sg_key]
        ),
        # Pad with empty chunks if we need more to reach minimum
        [
          for i in range(max(0, var.minimum_chunks_per_allowlist - length(concat(local.cidr_chunks[sg_key], local.prefix_list_chunks[sg_key])))) : []
        ]
      )
    }
  }

  # Generate a flattened map of all security group chunks
  allowlist_security_groups = merge([
    for sg_key, sg_value in local.chunked_security_groups : {
      for chunk_index, chunk in sg_value.chunks :
      "${sg_key}-${chunk_index + 1}" => {
        description   = "${sg_value.description} (Chunk ${chunk_index + 1})"
        ingress_rules = chunk
      }
    }
  ]...)
}

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "security_groups" {
  source = "../security-groups"

  security_groups = local.allowlist_security_groups
  vpc_id          = var.vpc_id
}
