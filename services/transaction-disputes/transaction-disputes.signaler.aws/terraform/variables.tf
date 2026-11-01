# variables.tf
# Manages input variable declarations resources.

variable "variable_map" {
  type = map(any)
  default = {
    buildNumber = ""
  }
}
