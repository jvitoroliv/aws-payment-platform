# test.tf
# Manages test Terraform configuration resources.


# Module sourced from internal registry — pin version to prevent unexpected changes
module "supportTool_ecs" {
  source            = "../../../modules/supportTool-ecs"
  vpc_id            = var.vpc_id
  environment       = var.environment
  region            = var.aws_region
  subnets_ids       = var.aws_private_subnets
  public_subnet_ids = var.aws_public_subnets
  image_name        = "registry.apps.example.com/tag/the-support-tool"
  hosted_zone_id    = var.hosted_zone // api.example.net
  domain            = var.api_domain
  alb_ssl_cert_arn  = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  dd_api_key        = var.dd_api_key
}

module "supportTool_static_site" {
  source              = "../../../modules/static-hosting"
  domain              = var.static_site_domain
  ssl_certificate_arn = var.ssl_cert_arn // *.platform.example.com

  ip_whitelist = [
    "10.200.1.0/24",   // Secure.platform.example.com VPN
    "198.51.100.1/32", // GlobalProtect VPN Users ME
    "198.51.100.2/32",    // VPC NAT for Smoketest
    "198.51.100.3/32",  // VPC NAT for Smoketest
    "198.51.100.4/32",   // VPC NAT for Smoketest
  ]

  hosted_zone_id = var.hosted_zone // api.example.net
  metric_name    = "supportToolIpWhitelistAcl"
}