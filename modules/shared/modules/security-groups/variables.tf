# variables.tf
# Part of the input variable declarations module.

variable "vpc_id" {
  description = "The VPC ID where the security groups will be created"
  type        = string
}

variable "security_groups" {
  default     = {}
  description = "A map of security groups to create, with security group name as the key"
  type = map(object({
    description = string
    ingress_rules = list(object({
      description                  = string
      from_port                    = number
      protocol                     = string
      to_port                      = number
      cidr_ipv4                    = optional(string)
      prefix_list_id               = optional(string)
      referenced_security_group_id = optional(string)
    }))
    egress_rules = optional(list(object({
      description                  = string
      from_port                    = number
      protocol                     = string
      to_port                      = number
      cidr_ipv4                    = optional(string)
      prefix_list_id               = optional(string)
      referenced_security_group_id = optional(string)
    })), [])
  }))
}
