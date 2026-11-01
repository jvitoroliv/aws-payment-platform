# outputs.tf
# Part of the output value definitions module.

output "records" {
  value = merge({
    for key, value in aws_route53_record.records : "https://${split("_", key)[0]}" => {
      (value.alias[0].name) = {
        weight = length(value.weighted_routing_policy) > 0 ? value.weighted_routing_policy[0].weight : null
      }
    }...
  })
}
