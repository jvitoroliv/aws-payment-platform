# secrets.tf
# Manages secrets Terraform configuration resources.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "mongo_pw" {
  source       = "./secret"
  secret_id    = "MONGO_PW"
  secret_value = "test"
}