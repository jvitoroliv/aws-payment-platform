# output.tf
# Part of the output Terraform configuration module.

output "api_invoke_url" {
  value = module.chronos.api_invoke_url
}

output "previous" {
  value = {
    active_region = local.active_region
    code_version  = local.code_version
  }
}
