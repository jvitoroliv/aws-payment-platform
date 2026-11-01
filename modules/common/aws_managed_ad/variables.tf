# variables.tf
# Part of the input variable declarations module.

# Documented in the module README with accepted ranges.
variable "dependencies" {
  description = "A list of module dependencies"
  default     = []
  type        = "list"
}

variable "directory_name" {
  description = "The FQDN of the domain"
}

# Type constraint catches misuse at plan time.
variable "directory_edition" {
  description = "The size of the AD, Standard or Enterprise"
}

variable "directory_type" {
  description = "What type of AWS Directory. This module only supports MicrosoftAD"
  default     = "MicrosoftAD"
}

variable "directory_password" {
  description = "The Admin password for the Directory"
}

variable "vpc_id" {
  description = "The VPC ID the Directory will go in"
}

variable "subnet_ids" {
  description = "The subnets that the DCs will be launched in. A minimum and a maximum of 2 AZs can be defined"
  type        = "list"
}

variable "ec2_ssm_domain_join_ou" {
  description = "The OU that the SSM document uses for instances that are domain joined"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = "map"
}
