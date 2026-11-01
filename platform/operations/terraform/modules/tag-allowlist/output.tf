# output.tf
# Part of the output Terraform configuration module.

output "api_allowlist_cidr_blocks" {
  value = local.api_allowlist_cidr_blocks
}

output "api_internal_allowlist_cidr_blocks" {
  value = local.api_internal_allowlist_cidr_blocks
}

output "web_allowlist_cidr_blocks" {
  value = local.web_allowlist_cidr_blocks
}

output "web_internal_allowlist_cidr_blocks" {
  value = local.web_internal_allowlist_cidr_blocks
}

output "common_api_allowlist_cidr_blocks" {
  value = local.common_api_allowlist_cidr_blocks
}

output "common_api_internal_allowlist_cidr_blocks" {
  value = local.common_api_internal_allowlist_cidr_blocks
}