# main.tf
# Part of the primary resource definitions module.

locals {
  auto_discovery_paths = {
    "dev"   = "aws"
    "test"  = "aws"
    "stage" = "aws"
    "prod"  = "aws"
  }

  raw_auto_secrets = try(
    [for name in nonsensitive(data.vault_kv_secrets_list_v2.auto_secrets.names) : name if name != "placeholder"],
    []
  )

  secret_configs = merge(
    { for name in local.raw_auto_secrets :
      name => {
        description         = "Synced from Vault: ${local.auto_discovery_paths[var.environment]}/${name}"
        from_vault          = true
        vault_mount         = "${var.environment}/kvv2"
        vault_path          = "${local.auto_discovery_paths[var.environment]}/${name}"
        vault_fields        = null
        vault_version       = null
        generate_random     = false
        random_length       = 32
        special_characters  = true
        value               = null
        rotation            = false
        rotation_lambda_arn = null
        auto_rotation_days  = 30
        enable_replica      = true
        secondary_region    = "us-west-2"
        tags                = {}
      }
    },
    var.secrets
  )

  vault_configs = {
    for k, v in local.secret_configs :
    k => v if v.from_vault == true
  }
}

data "vault_kv_secrets_list_v2" "auto_secrets" {
  mount = "${var.environment}/kvv2"
  name  = lookup(local.auto_discovery_paths, var.environment, "aws")
}

data "vault_kv_secret_v2" "vault_secrets" {
  for_each = local.vault_configs
  mount    = each.value.vault_mount
  name     = each.value.vault_path
  version  = each.value.vault_version
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "secrets" {
  source   = "../modules/secrets-manager"
  for_each = local.secret_configs

  name        = each.key
  description = each.value.description

  generate_random_password = each.value.generate_random
  random_password_length   = each.value.random_length
  special_characters       = each.value.special_characters

  secret_value = each.value.generate_random ? null : (
    each.value.from_vault ? (
      each.value.vault_fields != null ?
      {
        for field in each.value.vault_fields :
        field => data.vault_kv_secret_v2.vault_secrets[each.key].data[field]
        if contains(keys(data.vault_kv_secret_v2.vault_secrets[each.key].data), field)
      } :
      data.vault_kv_secret_v2.vault_secrets[each.key].data
      ) : (
      each.value.value != null ? { value = each.value.value } : null
    )
  )

  rotation_lambda_arn = each.value.rotation_lambda_arn
  auto_rotation_days  = each.value.auto_rotation_days
  enable_replica      = each.value.enable_replica
  secondary_region    = each.value.secondary_region

  tags = merge(
    each.value.tags != null ? each.value.tags : {},
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}
