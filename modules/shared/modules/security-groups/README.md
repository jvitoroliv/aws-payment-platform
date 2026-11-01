# Generic Security Groups Terraform Module

This module creates AWS Security Groups with configurable ingress and egress rules.

## Usage

```hcl
module "security_groups" {
  source      = "../modules/security-groups"
  vpc_id      = var.vpc_id

  security_groups = {
    app_server = {
      description = "Security group for application servers"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          description = "HTTPS from load balancer"
          cidr_ipv4   = "10.0.0.0/16"
        },
        {
          from_port      = 22
          to_port        = 22
          protocol       = "tcp"
          description    = "SSH access from prefix list"
          prefix_list_id = "pl-1234567890abcdef0"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          description = "Allow all outbound traffic"
          cidr_ipv4   = "0.0.0.0/0"
        }
      ]
    },
    database = {
      description = "Database security group"
      ingress_rules = [
        {
          from_port                    = 5432
          to_port                      = 5432
          protocol                     = "tcp"
          description                  = "Postgres from application servers"
          referenced_security_group_id = module.security_groups.security_group_ids["app_server"]
        }
      ]
    }
  }
}
```

## Input Variables

| Name | Description | Type | Required |
|------|-------------|------|----------|
| vpc_id | The VPC ID where the security groups will be created | string | yes |
| security_groups | A map of security groups to create | map(object) | yes |

### Security Group Object Structure

```hcl
{
  description = string
  ingress_rules = list(object({
    from_port                    = number
    to_port                      = number
    protocol                     = string
    description                  = string
    cidr_ipv4                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  egress_rules = optional(list(object({
    from_port                    = number
    to_port                      = number
    protocol                     = string
    description                  = string
    cidr_ipv4                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  })), [])
}
```

## Output Values

| Name | Description |
|------|-------------|
| security_group_ids | Map of security group names to their IDs |
| security_groups | Map of all security group resources |

## AWS Provider Requirements

This module uses the AWS VPC Security Group Rule resources (introduced in AWS Provider 4.0+). Make sure your AWS provider version is at least 4.0 or higher.
