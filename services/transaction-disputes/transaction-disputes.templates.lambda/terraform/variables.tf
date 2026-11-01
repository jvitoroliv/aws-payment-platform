# variables.tf
# Part of the input variable declarations module.

variable "variable_map" {
  type = map(any)
  default = {
    buildNumber = ""
  }
}
