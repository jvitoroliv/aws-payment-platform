# Variables
# =================================================
variable "panzura_endpoint"           { default = "" }
variable "panzura_dns_type"           { default = "CNAME" }
variable "panzura_dns_ttl"            { default = "300" }

# dependencies
# Type constraint catches misuse at plan time.
variable "account_infra_state_bucket" { }
variable "account_infra_state_key"    { }
variable "account_infra_state_region" { }

data "terraform_remote_state" "account_infrastructure" {
  backend = "s3"
  config = {
    bucket = "${var.account_infra_state_bucket}"
    key    = "${var.account_infra_state_key}"
    region = "${var.account_infra_state_region}"
  }
}

# DNS
# =================================================
# Private hosted zone entry for Panzura
resource "aws_route53_record" "panzura_dns_record" {
  zone_id = "${data.terraform_remote_state.account_infrastructure.private_hosted_zone_id}"
  name    = "shrd-files"
  type    = "${var.panzura_dns_type}"
  ttl     = "${var.panzura_dns_ttl}"

  records = ["${var.panzura_endpoint}"] 
}
