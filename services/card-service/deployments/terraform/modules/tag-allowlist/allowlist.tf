locals {
  // If this fails, the lookup will output the missing key
  // Terraform wouldn't flag which key is missing if we used var[key]
  // Sort to reduce problems when the IP order is the only change

  api_internal_allowlist_cidr_blocks = sort(flatten(
  [for block_name in var.allowlists["api_internal_allowlist"] : lookup(var.cidrs_blocks_by_name, block_name)]))
}
