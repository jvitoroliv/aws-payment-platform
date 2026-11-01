# output.tf
# Part of the output Terraform configuration module.

output "ecs" {
  description = "ECS resources created by the module"
  value = module.aws_ecs
}

output "load_balancers" {
  description = "Load balancers created by the module"
  value = module.aws_alb.wrapper
}
