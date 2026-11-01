# output.tf
# Part of the output Terraform configuration module.

output "security_group_chunk_composition" {
  description = "Composition of each security group chunk showing CIDR rule count and Prefix List IDs"
  value = {
    for chunk_name, chunk_data in local.allowlist_security_groups : chunk_name => {
      cidr_rules = length([
        for rule in chunk_data.ingress_rules : rule if rule.type != "prefix_list"
      ])
      prefix_lists = [
        for rule in chunk_data.ingress_rules : rule.prefix_list_id
        if rule.type == "prefix_list"
      ]
    }
  }
}

output "security_group_ids" {
  value = module.security_groups.security_group_ids
}

output "security_group_ids_by_allowlist_name" {
  description = "Map of base security group names to a list of all their chunked security group IDs"
  value = {
    for allowlist_name in keys(var.allowlists) : allowlist_name => [
      for sg_key, sg_id in module.security_groups.security_group_ids :
      sg_id if startswith(sg_key, "${allowlist_name}-")
    ]
  }
}
