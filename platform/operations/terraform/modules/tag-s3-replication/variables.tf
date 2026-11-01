# variables.tf
# Manages input variable declarations resources.

variable "environment" {
  type = string
}
# Defaults are production-safe; override per environment.
variable "aws_region" {
  type = string
}
variable "replication_aws_region" {
  type = string
}
variable "aws_account_number" {
  type = string
}

# Documented in the module README with accepted ranges.
variable "regular_file_expiration_days" {
  default = 365
  type    = number
}

variable "regular_file_transition_days" {
  default = 30
  type    = number
}

variable "critical_file_expiration_days" {
  default = 790
  type    = number
}

variable "critical_file_transition_days" {
  default = 730
  type    = number
}

variable "long_term_file_expiration_days" {
  default = 2556
  type    = number
}

variable "long_term_file_transition_days" {
  default = 730
  type    = number
}

variable "include_lifecycle_rule" {
  default = true
  type    = bool
}

variable "destroy" {
  default = false
  type    = bool
}

variable "aws_kms_arn_secondary" {
  type = string
}

variable "aws_kms_arn_primary" {
  type = string
}

variable "data_services_kms_key_id" {
  type = string
}

variable "additional_replication_rules" {
  default = []
  type = list(
    object({
      delete_marker_replication = bool
      enabled                   = bool
      id                        = string
      prefix                    = string
      destination = object({
        bucket_arn         = string
        replica_kms_key_id = string
        metrics = optional(
          object({
            enabled = bool
            event_threshold = object({
              minutes = number
            })
            replication_time = object({
              enabled = bool
              time = object({
                minutes = number
              })
            })
          })
        )
      })
      source = object({
        sse_kms_encrypted_objects = bool
      })
    })
  )
}

variable "data_services_key_policies" {
  default = []
  type = list(
    object({
      action = list(string)
      condition = optional(
        object({
          test     = string
          variable = string
          values   = list(string)
        })
      )
      effect       = string
      principal    = list(string)
      resource     = list(string)
      statement_id = optional(string)
    })
  )
}

variable "data_services_s3_access_policies" {
  default = []
  type = list(
    object({
      actions      = list(string) # S3 permissions that will target the S3 bucket resource e.g. "s3:GetBucketLocation", "s3:ListBucket", "s3:ListAllMyBuckets"
      principal    = string       # The AWS principal that will be assigned the permissions
      resources    = list(string) # S3 resources that will be targeted by the actions e.g. "path/file/1/*". String "<bucket-arn>" will be replaced with the actual bucket ARN.
      statement_id = optional(string)
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })))
    })
  )
}
