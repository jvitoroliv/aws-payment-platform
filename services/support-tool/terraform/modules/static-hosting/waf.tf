# waf.tf
# Manages waf Terraform configuration resources.

resource "aws_waf_ipset" "ipset" {
  name = format("%s-ip-whitelist", var.domain)

  dynamic "ip_set_descriptors" {
    for_each = [for ip in var.ip_whitelist : {
      ip = ip
    }]

    content {
      type  = "IPV4"
      value = ip_set_descriptors.value.ip
    }
  }
}

resource "aws_waf_rule" "waf_rule" {
  name        = format("%s-ip-whitelist", var.domain)
  metric_name = var.metric_name

  predicates {
    data_id = aws_waf_ipset.ipset.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_web_acl" "waf_acl" {
  name        = format("%s-ip-whitelist", var.domain)
  metric_name = var.metric_name

  default_action {
    type = "BLOCK"
  }

  rules {
    action {
      type = "ALLOW"
    }

    priority = 1
    rule_id  = aws_waf_rule.waf_rule.id
    type     = "REGULAR"
  }
}