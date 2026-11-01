# test.tf
# Part of the test Terraform configuration module.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "mock-service" {
  source              = "../../../modules/mock-service"
  environment         = var.environment
  api_url             = var.api_url
  aws_region          = var.aws_region
  aws_vpc_id          = var.aws_vpc_id
  dns_zone_id         = var.dns_zone_id
  dd_api_key_arn      = local.datadog_secret_arn
  aws_account_number  = var.aws_account_number
  aws_private_subnets = var.aws_private_subnets
  aws_public_subnets  = var.aws_public_subnets
  mock_version       = var.mock_version
  certificate_arn     = var.certificate_arn
  chronos_api_url     = var.chronos_api_url
  is_superJail        = var.environment != "test" ? true : false
}
