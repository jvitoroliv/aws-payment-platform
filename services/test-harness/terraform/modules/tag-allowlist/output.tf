# output.tf
# Part of the output Terraform configuration module.

output "security_groups_ingress" {
  value = local.security_groups_ingress
}

