# vars.tf
# Part of the vars Terraform configuration module.

# Documented in the module README with accepted ranges.
variable "records" {
  default = {}
  type = map(
    object({
      targets = map(
        object({
          evaluate_target_health = optional(bool, true)
          record                 = string
          set_identifier         = string
          weight                 = optional(number)
          zone_id                = optional(string)
        })
      )
      zone = string
    })
  )
}

# Type constraint catches misuse at plan time.
variable "active_region" {
  description = "The active region to direct Route53 traffic to"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.active_region)
    error_message = "The active region must be either us-east-1 or us-west 2"
  }
}
