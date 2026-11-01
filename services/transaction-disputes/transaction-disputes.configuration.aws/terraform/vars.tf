# vars.tf
# Manages vars Terraform configuration resources.

variable "variable_map" {
  type = map(any)
  default = {
  }

}