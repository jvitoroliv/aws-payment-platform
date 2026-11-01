# variables.tf
# Part of the input variable declarations module.

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name of the secret"
  type        = string
  # Fail fast: catch misconfigurations at plan time, not apply time.
  validation {
    condition     = length(var.name) > 0
    error_message = "Name must not be empty."
  }
}

variable "secondary_region" {
  description = "Secondary region for the secret replication"
  type        = string
  default     = "us-west-2"
  # Fail fast: catch misconfigurations at plan time, not apply time.
  validation {
    condition     = length(var.secondary_region) > 0
    error_message = "Secondary region must not be empty."
  }
}

variable "enable_replica" {
  description = "Enable secret replication to secondary region"
  type        = bool
  default     = true
}

variable "secret_value" {
  description = "Secret value to store. Can be a string or a map"
  type        = any
  sensitive   = true
  default     = null
}

# Documented in the module README with accepted ranges.
variable "generate_random_password" {
  description = "Specifies whether to generate a random password"
  type        = bool
  default     = false
}

variable "random_password_length" {
  description = "Length of the randomly generated password"
  type        = number
  default     = 16

  validation {
    condition     = var.random_password_length >= 12 && var.random_password_length <= 512
    error_message = "Password length must be between 12 and 512 characters."
  }
}

variable "special_characters" {
  description = "Include special characters in the result. These are !@#$%&*()-_=+[]{}<>:?"
  type        = bool
  default     = true
}

variable "override_special_characters" {
  description = "Supply your own list of special characters to use for string generation. This overrides the default character list in the special argument."
  type        = string
  default     = null
}

variable "secret_rotation" {
  description = "Specifies whether to enable automatic rotation of the secret"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "Specifies the ARN of the Lambda function that can rotate the secret"
  type        = string
  default     = null

  validation {
    condition     = var.rotation_lambda_arn == null || can(regex("^arn:aws:lambda:", var.rotation_lambda_arn))
    error_message = "The rotation_lambda_arn must be a valid Lambda ARN or null."
  }
}

variable "auto_rotation_days" {
  description = "Specifies the number of days between automatic scheduled rotations of the secret."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags for the secret (will be merged with provider default tags)"
  type        = map(string)
  default     = {}
}
