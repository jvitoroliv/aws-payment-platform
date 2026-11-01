# security_groups.tf
# Part of the security group rules module.

resource "aws_security_group" "this" {
  for_each    = var.security_groups
  name        = each.key
  description = each.value.description
  vpc_id      = var.vpc_id

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each = {
    for pair in flatten([
      for security_group_name, security_group in var.security_groups : [
        for rule in security_group.ingress_rules : {
          rule                = rule
          security_group_name = security_group_name
          # Create a hash key for deduplication - rules with same properties will have same hash
          hash_key = "${security_group_name}_${rule.from_port}_${rule.to_port}_${rule.protocol}_${rule.referenced_security_group_id != null ? rule.referenced_security_group_id : ""}${rule.cidr_ipv4 != null ? rule.cidr_ipv4 : ""}${rule.prefix_list_id != null ? rule.prefix_list_id : ""}"
        }
      ]
      # Use the hash_key instead of just index to prevent duplicate rules
    ]) : pair.hash_key => pair
  }

  description       = each.value.rule.description
  from_port         = each.value.rule.from_port
  ip_protocol       = each.value.rule.protocol
  security_group_id = aws_security_group.this[each.value.security_group_name].id
  to_port           = each.value.rule.to_port

  # Use one of the following based on the rule type - only one can be specified per rule
  cidr_ipv4                    = each.value.rule.cidr_ipv4
  prefix_list_id               = each.value.rule.prefix_list_id
  referenced_security_group_id = each.value.rule.referenced_security_group_id

  # Ensure security groups exist before creating rules that could reference them
  depends_on = [
    aws_security_group.this
  ]

  # Lifecycle rules prevent Terraform from reverting auto-scaler changes.
  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  for_each = {
    for pair in flatten([
      for security_group_name, security_group in var.security_groups : [
        for rule in security_group.egress_rules : {
          rule                = rule
          security_group_name = security_group_name
          # Create a hash key for deduplication - rules with same properties will have same hash
          hash_key = "${security_group_name}_${rule.from_port}_${rule.to_port}_${rule.protocol}_${rule.referenced_security_group_id != null ? rule.referenced_security_group_id : ""}${rule.cidr_ipv4 != null ? rule.cidr_ipv4 : ""}${rule.prefix_list_id != null ? rule.prefix_list_id : ""}"
        }
      ]
      # Use the hash_key instead of just index to prevent duplicate rules
    ]) : pair.hash_key => pair
  }

  description       = each.value.rule.description
  from_port         = each.value.rule.from_port
  ip_protocol       = each.value.rule.protocol
  security_group_id = aws_security_group.this[each.value.security_group_name].id
  to_port           = each.value.rule.to_port

  # Use one of the following based on the rule type - only one can be specified per rule
  cidr_ipv4                    = each.value.rule.cidr_ipv4
  prefix_list_id               = each.value.rule.prefix_list_id
  referenced_security_group_id = each.value.rule.referenced_security_group_id

  # Ensure security groups exist before creating rules that could reference them
  depends_on = [
    aws_security_group.this
  ]

  lifecycle { create_before_destroy = true }
}
