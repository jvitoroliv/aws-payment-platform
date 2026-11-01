# output.tf
# Part of the output Terraform configuration module.

output "api_internal_allowlist_cidr_blocks" {
  value = local.api_internal_allowlist_cidr_blocks
}
