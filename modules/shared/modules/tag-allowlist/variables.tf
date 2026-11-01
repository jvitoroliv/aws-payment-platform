# variables.tf
# Part of the input variable declarations module.

variable "allowlists" {
  type = map(
    object({
      description = string
      rules = list(
        object({
          sources   = list(string)
          from_port = number
          to_port   = number
          protocol  = string
        })
      )
    })
  )
  description = "Map of allowlists with security group rules"
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

# Documented in the module README with accepted ranges.
variable "max_rules_per_security_group" {
  description = "Maximum number of rules per security group (AWS limit is 60 by default)"
  type        = number
  default     = 120
}

variable "minimum_chunks_per_allowlist" {
  default     = 1
  description = "Create this many security groups/chunks for an allowlist even if it has no rules"
  type        = number
}

variable "prefix_lists_by_name" {
  type = map(
    map(string)
  )
  default = {
    "example" = {
      us-east-1 = "pl-12345678"
      us-west-2 = "pl-23456789"
    },
    "example 2" = {
      us-east-1 = "pl-abcdef12"
      us-west-2 = "pl-fedcba98"
    }
  }
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}
