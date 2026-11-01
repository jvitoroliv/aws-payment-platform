# test.tf
# Part of the test Terraform configuration module.


# Module sourced from internal registry — pin version to prevent unexpected changes
module "supportTool_ecs" {
  source            = "../../../modules/supportTool-ecs"
  vpc_id            = var.aws_vpc_id
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
