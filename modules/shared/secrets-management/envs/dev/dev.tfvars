environment = "dev"

# Secret configuration:
# See comprehensive documentation in /secrets-management/README.md for all available
# options and examples for configuring secrets from Vault, random generation, or direct values.

secrets = {
  # Add your actual secrets here
  "database-credentials7" = {
    description = "Complete database credentials"
    from_vault  = true
    vault_mount = "/dev/kvv2"
    vault_path  = "test"
  }
}
