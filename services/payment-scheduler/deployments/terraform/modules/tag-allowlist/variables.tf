# variables.tf
# Part of the input variable declarations module.

variable "allowlists" {
  type = map(list(string))
  default = {
    "api_allowlist"          = ["example", "example 2"],
    "api_internal_allowlist" = ["example"],
    "web_allowlist"          = ["example"],
    "common_api_allowlist"   = ["example"],
  }
}


variable "cidrs_blocks_by_name" {
  type = map(list(string))
  default = {
    "example" = [
      "10.10.10.10/32"
    ],
    "example 2" = [
      "8.8.8.8/32"
    ]
  }
}