locals {
  # Configuration variables
  artifactory_secret = "registry_cloud_credentials"
  aws_region_short   = var.aws_region == "us-east-1" ? "ue1" : "uw2"
  # card_service_db_username       = "github-actions-runner-iam"
  card_service_db_username       = "github-actions-runner"
  card_service_db_password       = "${var.environment}-github-actions-runner-aurora-password"
  cidr_vpc_local                 = var.aws_region == "us-east-1" ? var.cidr_vpc_ue1 : var.cidr_vpc_uw2
  crowdstrike_secret             = "endpoint_security_cid"
  endpoint_security_cid_arg_secret_arn = "${data.aws_secretsmanager_secret.crowdstrike.arn}:endpoint_security_cid::" # "endpoint_security_cid" is the JSON key within the secret
  datadog_secret                 = "datadog-api-key"
  datadog_secret_arn             = "${data.aws_secretsmanager_secret_version.datadog-api-key.arn}:datadog-api-key::" # "datadog-api-key" is the JSON key within the secret
  datadog_api_key                = jsondecode(data.aws_secretsmanager_secret_version.datadog-api-key.secret_string)
  shared_region                  = var.aws_region == "us-east-1" ? "east" : "west"
  shared_state_key               = "shared-${local.shared_region}-${var.environment}.tfstate"

  hsm_sg_rule_json = var.hsm_cidr == null ? {} : {
    hsm_sg_rule = {
      description = "Allow outbound traffic to the HSM"
      from_port   = 1500
      to_port     = 1500
      protocol    = "tcp"
      cidr_blocks = [var.hsm_cidr]
      type        = "egress"
    }
  }

  db_state_bucket = {
    dev   = "corp-subprod-terraform-state-store-us-east-1"
    test  = "corp-subprod-terraform-state-store-us-east-1"
    stage = "corp-stage-terraform-state-store-us-east-1"
    prod  = "corp-prod-terraform-state-store-us-east-1"
  }

  shared_state_bucket = {
    dev   = "corp-subprod-terraform-state-store-${var.aws_region}"
    test  = "corp-subprod-terraform-state-store-${var.aws_region}"
    stage = "corp-stage-terraform-state-store-${var.aws_region}"
    prod  = "corp-prod-terraform-state-store-${var.aws_region}"
  }
}
