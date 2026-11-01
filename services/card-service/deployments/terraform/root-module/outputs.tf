# outputs.tf
# Manages output value definitions resources.

output "db_users" {
  value = {
    for name, user in var.postgres_users : name => {
      auth_token_generation_command = user.iam_auth ? "aws rds generate-db-auth-token --hostname ${data.terraform_remote_state.card_service_db.outputs.writer_cluster.endpoint} --port ${data.terraform_remote_state.card_service_db.outputs.writer_cluster.port} --username ${name}" : null
      iam_auth                      = user.iam_auth
      password_secret_arn           = user.iam_auth ? null : data.aws_secretsmanager_secret_version.postgres_user_password[name].arn
      password_secret_name          = user.iam_auth ? null : user.password_secret_name
      roles                         = user.roles
    }
  }
}

output "aws_caller_identity" {
  value = data.aws_caller_identity.current
}
