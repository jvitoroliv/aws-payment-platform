# variables.tf
# Part of the input variable declarations module.

variable "backup_retention_period" {
  description = "The number of days to retain RDS automated backups for. Cluster can be restored to any point-in-time within this period. Maixumum value is 35 days."
  type        = number
}

variable "backup_frequency" {
  type        = string
  default     = "hourly"
  description = "Backup frequency. Possible values: 'daily' or 'hourly'."
  # Fail fast: catch misconfigurations at plan time, not apply time.
  validation {
    condition     = contains(["daily", "hourly"], var.backup_frequency)
    error_message = "Valid values for backup_frequency are daily or hourly."
  }
}

# Defaults are production-safe; override per environment.
variable "aws_account_name" {
  description = "AWS account name"
  type        = string
}

# Type constraint catches misuse at plan time.
variable "engine_version" {
  description = "Version of the Aurora Postgres engine"
  type        = string
}

variable "environment" {
  description = "Environment to deploy the Aurora Postgres clusters"
  type        = string
}

variable "instance_class" {
  description = "Class of the RDS instances"
  type        = string
}

# Documented in the module README with accepted ranges.
variable "name" {
  description = "Name to give created resources"
  type        = string
}

# Input validation ensures callers provide sane values.
variable "postgres_databases" {
  default     = {}
  description = "Databases to create in the primary cluster"
  type = map(
    object({
      allow_connections = optional(bool)
      connection_limit  = optional(number)
      encoding          = optional(string)
      lc_collate        = optional(string)
      lc_ctype          = optional(string)
      owner             = optional(string)
      tablespace_name   = optional(string)
      template          = optional(string)
    })
  )
}

variable "postgres_database_owner_roles" {
  default     = {}
  description = "Roles to create in the primary cluster. These are created before the databases from var.postgres_databases are created so they be assigned as owners."
  type = map(
    object({
      bypass_row_level_security = optional(bool)
      create_database           = optional(bool)
      create_role               = optional(bool)
      inherit                   = optional(bool)
      replication               = optional(bool)
      roles                     = optional(list(string))
      search_path               = optional(list(string))
      skip_drop_role            = optional(bool)
      skip_reassign_owned       = optional(bool)
      statement_timeout         = optional(string)
    })
  )
}

variable "postgres_grants" {
  default     = {}
  description = "Grants to apply to roles in the primary cluster"
  type = map(
    object({
      columns           = optional(list(string))
      database          = string
      object_type       = string
      objects           = optional(list(string))
      privileges        = list(string)
      role              = string
      schema            = optional(string)
      with_grant_option = optional(bool)
    })
  )
}

variable "postgres_extensions" {
  default     = {}
  description = "Extensions to install in the primary cluster"
  type = map(
    object({
      create_cascade = optional(bool, false)
      database       = optional(string)
      drop_cascade   = optional(bool, false)
      schema         = optional(string)
      version        = optional(string)
    })
  )
}

variable "postgres_roles" {
  default     = {}
  description = "Roles to create in the primary cluster"
  type = map(
    object({
      bypass_row_level_security = optional(bool)
      create_database           = optional(bool)
      create_role               = optional(bool)
      inherit                   = optional(bool)
      replication               = optional(bool)
      roles = optional(
        map(
          object({
            with_admin_option = optional(bool, false)
          })
        )
      )
      search_path         = optional(list(string))
      skip_drop_role      = optional(bool)
      skip_reassign_owned = optional(bool)
      statement_timeout   = optional(string)
    })
  )
}

variable "postgres_users" {
  default     = {}
  description = "Login roles to create in the primary cluster"
  type = map(
    object({
      assume_role          = optional(string)
      connection_limit     = optional(number)
      create_database      = optional(bool)
      create_role          = optional(bool)
      encrypted_password   = optional(bool)
      iam_auth             = optional(bool, false)      # Defaults to password auth. When set to 'true', 'password_secret_name' and 'encrypted_password' are ignored
      iam_roles            = optional(list(string), []) # Allow IAM roles to connect as the user
      inherit              = optional(bool)
      password_secret_name = optional(string)
      roles = optional(
        map(
          object({
            with_admin_option = optional(bool, false)
          })
        )
      )
      search_path       = optional(list(string))
      statement_timeout = optional(string)
      valid_until       = optional(string)
    })
  )
}

variable "primary" {
  description = "Primary cluster configuration"
  type = object({
    instances = map(any)
    subnets   = list(string)
    vpc_id    = string
  })
}

variable "secondary" {
  description = "Secondary cluster configuration"
  type = object({
    instances = map(any)
    subnets   = list(string)
    vpc_id    = string
  })
}

variable "security_group_rules" {
  description = "Security Group Rules to create for the Aurora Postgres clusters"
  type = map(
    object({
      cidr_blocks              = optional(list(string))
      cluster                  = optional(string, "all") # "all", "primary", "secondary"
      description              = optional(string)
      from_port                = number
      protocol                 = string
      source_security_group_id = optional(string)
      to_port                  = number
    })
  )
}

variable "parameter_group_parameters" {
  default = []

  type = list(
    object({
      name         = string
      value        = string
      apply_method = string
    })
  )
}

variable "db_cluster_parameter_group_family" {
  description = "The family of the DB cluster parameter group"
  type        = string
}
