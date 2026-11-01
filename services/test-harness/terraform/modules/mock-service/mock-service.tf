# mock-service.tf
# Part of the mock-service Terraform configuration module.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "iam" {
  source               = "../tag-iam"
  environment          = var.environment
  aws_region           = var.aws_region
  aws_account_number   = var.aws_account_number
  eks_oidc_provider_id = var.eks_oidc_provider_id
}

module "allowlist" {
  source = "../tag-allowlist"
  cidrs_blocks_by_name = jsondecode(
  file("${path.module}/../../configuration/allowlists/cidrs_blocks_by_name.json"))
  allowlists = jsondecode(
  file("${path.module}/../../configuration/allowlists/${var.environment}.json"))
}

# Shared module — changes here affect all consumers. Semver applies.
module "mock-service" {
  source            = "../tag-mock-ecs"
  iam_role_arn      = module.iam.th_iam_role_arn
  environment       = var.environment
  subnet_ids        = var.aws_private_subnets
  public_subnet_ids = var.aws_public_subnets
  aws_region        = var.aws_region
  aws_vpc_id        = var.aws_vpc_id
  th_image          = "registry.example.io/docker-nonprod/app/test-harness:${var.mock_version}"
  coreplatform_image   = "registry.example.io/docker-nonprod/app/mock-coreplatform:${var.mock_version}"
  chronos_image     = "registry.example.io/docker-nonprod/app/mock-chronos:${var.mock_version}"
  dns_zone_id       = var.dns_zone_id
  dd_api_key_arn    = var.dd_api_key_arn
  api_url           = var.api_url
  log_lambda_name   = "${var.environment}-${var.aws_region}-ecs-logconsumer-lambda"
  web_ssl_cert_arn  = var.certificate_arn
  chronos_api_url   = var.chronos_api_url
  idle_timeout      = 3600
  is_superJail      = var.is_superJail
  ingress_whitelist = module.allowlist.security_groups_ingress
  egress_whitelist  = ["0.0.0.0/0"]
}
