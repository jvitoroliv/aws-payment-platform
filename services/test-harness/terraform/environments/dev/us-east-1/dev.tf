# dev.tf
# Manages dev Terraform configuration resources.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "mock-service" {
  source               = "../../../modules/mock-service"
  environment          = var.environment
  api_url              = var.api_url
  aws_region           = var.aws_region
  aws_vpc_id           = var.aws_vpc_id
  dns_zone_id          = var.dns_zone_id
  dd_api_key_arn       = local.datadog_secret_arn
  aws_account_number   = var.aws_account_number
  aws_private_subnets  = var.aws_private_subnets
  aws_public_subnets   = var.aws_public_subnets
  mock_version        = var.mock_version
  certificate_arn      = var.certificate_arn
  is_superJail         = var.environment != "dev" ? true : false
  eks_oidc_provider_id = var.eks_oidc_provider_id
}

module "mock-sftp" {
  source              = "../../../modules/sftp"
  aws_account_number  = var.aws_account_number
  aws_private_subnets = var.aws_private_subnets
  aws_region          = var.aws_region
  aws_vpc_id          = var.aws_vpc_id
  environment         = var.environment
}
