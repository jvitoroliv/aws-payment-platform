locals {
  // if for some reason fails, lookup will output the key that was not found
  // if using var[key] terraform will not inform which one is missing
  // we sort so reduce problems when jus the or der of ips change
  security_groups_ingress = sort(flatten(
  [for block_name in var.allowlists["security_groups_ingress"] : lookup(var.cidrs_blocks_by_name, block_name)]))
}