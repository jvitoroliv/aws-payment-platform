# dns.tf
# Part of the dns Terraform configuration module.

# Apex DNS
resource "aws_route53_record" "payments_scheduler_apex_api_internal_dns_name" {
  allow_overwrite = true
  zone_id         = var.dns_zone_id
  name            = var.api_internal_fqdns_name
  type            = "A"
  alias {
    evaluate_target_health = false
    name                   = format("%v", aws_lb.payments_scheduler_api_internal_lb.dns_name)
    zone_id                = format("%v", aws_lb.payments_scheduler_api_internal_lb.zone_id)
  }
  depends_on = [aws_lb.payments_scheduler_api_internal_lb]
}