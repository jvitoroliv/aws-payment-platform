# shared.tf
# Part of the shared Terraform configuration module.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "iam" {
  source             = "../modules/tag-iam"
  aws_account_number = local.aws_account
  aws_region         = var.aws_region
  environment        = var.environment
  external_id        = local.external_id
}

module "s3-buckets" {
  source      = "../modules/s3-buckets"
  aws_region  = var.aws_region
  environment = var.environment
}

module "allowlist" {
  source = "../modules/tag-allowlist"

  region = var.aws_region
  vpc_id = local.tenancy.vpc_id

  allowlists = jsondecode(
    file("${path.module}/../configurations/allowlists/${var.environment}.json")
  )

  cidrs_blocks_by_name = jsondecode(
    file("${path.module}/../configurations/allowlists/cidrs_blocks_by_name.json")
  )

  prefix_lists_by_name = jsondecode(
    file("${path.module}/../configurations/allowlists/prefix_lists_by_name.json")
  )
}

module "security_groups" {
  source = "../modules/security-groups"

  security_groups = var.security_groups
  vpc_id          = local.tenancy.vpc_id
}

module "Splunk-logger" {
  source              = "../modules/splunk-logger"
  aws_account_number  = local.aws_account
  aws_private_subnets = local.tenancy.subnets.private
  aws_region          = var.aws_region
  aws_vpc_id          = local.tenancy.vpc_id
  environment         = var.environment
  memory_size         = var.splunk_memory_size
  source_s3_bucket    = module.s3-buckets.aws_s3_bucket_name
  source_s3_key       = local.aws_vars.splunklogger.source_s3_key
  splunk_dest         = var.splunk_dest

}

module "Splunk-logger-s3" {
  source              = "../modules/splunk-logger-s3"
  aws_private_subnets = local.tenancy.subnets.private
  aws_region          = var.aws_region
  aws_vpc_id          = local.tenancy.vpc_id
  environment         = var.environment
  memory_size         = var.splunk_memory_size
  splunk_dest         = var.splunk_dest
}

module "private-dns" {
  source      = "../modules/private-dns"
  domain      = var.domain
  environment = var.environment
  vpc_id      = local.tenancy.vpc_id
}

module "vpc" {
  source           = "../modules/vpc"
  atlas_cidr_ue1   = local.peering.us-east-1.cidr
  atlas_cidr_uw2   = local.peering.us-west-2.cidr
  atlas_pcx_ue1    = local.peering.us-east-1.connection
  atlas_pcx_uw2    = local.peering.us-west-2.connection
  aws_region       = var.aws_region
  aws_route_tables = local.tenancy.private_route_tables
  environment      = var.environment
  private_subnets  = local.tenancy.subnets.private
  vpc_id           = local.tenancy.vpc_id
}
