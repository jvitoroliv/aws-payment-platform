locals {
  // if for some reason fails, lookup will output the key that was not found
  // if using var[key] terraform will not inform which one is missing
  // we sort so reduce problems when jus the or der of ips change

  api_internal_allowlist_cidr_blocks = sort(flatten(
    [for block_name in var.allowlists["api_internal_allowlist"] : lookup(var.cidrs_blocks_by_name, block_name)]
  ))
}
