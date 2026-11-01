# atc.tf
# Part of the atc Terraform configuration module.

data "aws_route53_zone" "zones" {
  for_each = toset(distinct([for v in values(var.records) : v.zone]))

  name         = each.key
  private_zone = false
}

resource "aws_route53_record" "records" {
  # Create a Route53 record for each target in var.records
  for_each = merge(
    [
      for record_key, record_value in var.records : {
        for target_key, target_value in record_value.targets :
        "${record_key}_${target_key}" => {
          alias_zone_id          = target_value.zone_id
          name                   = record_key
          evaluate_target_health = target_value.evaluate_target_health
          set_identifier         = target_value.set_identifier
          target                 = target_value.record
          weight                 = local.region_weights[target_key]
          zone                   = record_value.zone
        }
      }
    ]...
  )

  allow_overwrite = false
  name            = each.value.name
  set_identifier  = each.value.set_identifier
  type            = "A"
  zone_id         = data.aws_route53_zone.zones[each.value.zone].zone_id

  alias {
    evaluate_target_health = each.value.evaluate_target_health
    name                   = each.value.target
    zone_id                = each.value.alias_zone_id != null ? each.value.alias_zone_id : data.aws_route53_zone.zones[each.value.zone].zone_id
  }

  dynamic "weighted_routing_policy" {
    for_each = each.value.weight != null ? [each.value.weight] : []

    content {
      weight = weighted_routing_policy.value
    }
  }
}
