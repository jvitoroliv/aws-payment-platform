#global
variable environment { default = "dev" }
variable region { default = "us-east-1" }
variable aiven_project { default = "dev" }

#ACL Resources
variable acl_permission { default = "admin" }

#Schema Configurations
variable "manage_schema" {
  default     = true
  description = "Defaults to true. If set to false, schema and schema registry ACL will not be created."
  type        = bool
}

variable schema_compatability_level { default = "BACKWARD"}
variable schema_configuration {}
variable key_schema_configuration {
  default     = null
  description = "Schema configuration for the Key Schema"
  type        = any
}
variable schema_subject_name {
  description = "The full name of the Value Schema Subject"
  type        = string
}
variable key_schema_subject_name {
  default     = null
  description = "The full name of the Key Schema Subject"
  type        = string
}

#Topic Resources
variable topic_cleanup_policy { default = "compact,delete" }
variable topic_partition { default = 2 }
variable topic_replication { default = 2 }
variable topic_retention_time { default = "2592000000" } #720 hours
variable topic_termination_protection { default = false }
variable topic_title { default = "tag_test_topic" }

#User Configuration
variable aiven_user { default = "aiven_poc_user" }