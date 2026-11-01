# variables.tf
# Part of the input variable declarations module.

# Defaults are production-safe; override per environment.
variable "secrets" {
  description = "Map of secrets to create"
  type = map(object({
    description         = optional(string, "")
    generate_random     = optional(bool, false)
    random_length       = optional(number, 32)
    special_characters  = optional(bool, true)
    value               = optional(any, null)
    from_vault          = optional(bool, false)
    vault_mount         = optional(string, null)
    vault_path          = optional(string, null)
    vault_fields        = optional(list(string), null)
    vault_version       = optional(number, null)
    rotation            = optional(bool, false)
    rotation_lambda_arn = optional(string, null)
    auto_rotation_days  = optional(number, 30)
    enable_replica      = optional(bool, true)
    secondary_region    = optional(string, "us-west-2")
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "environment" {
  description = "Environment (dev, test, stage, prod)"
  type        = string
}
