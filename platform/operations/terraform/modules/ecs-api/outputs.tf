# outputs.tf
# Part of the output value definitions module.

output "internal_alb_listener_arns" {
  value = module.api-lb-internal.alb_listener_arns
}

output "internal_alb_security_groups" {
  value = module.api-lb-internal.alb_security_groups
}
