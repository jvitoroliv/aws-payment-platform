# outputs.tf
# Part of the output value definitions module.

output "priv_dns_zone_id" {
  value = aws_route53_zone.tag_private.zone_id
}

output "priv_dns_name" {
  value = aws_route53_zone.tag_private.name
}

output "priv_dns_id" {
  value = aws_route53_zone.tag_private.id
}