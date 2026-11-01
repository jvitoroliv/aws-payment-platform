# main.tf
# Manages primary resource definitions resources.

resource "aws_secretsmanager_secret" "secret" {
  description = var.description
  name        = var.name

  dynamic "replica" {
    for_each = var.enable_replica ? [1] : []
    content {
      region = var.secondary_region
    }
  }

  tags = var.tags
}

resource "random_password" "password" {
  count = var.generate_random_password ? 1 : 0

  length           = var.random_password_length
  special          = var.special_characters
  override_special = var.override_special_characters
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id = aws_secretsmanager_secret.secret.id

  secret_string = var.generate_random_password ? random_password.password[0].result : (
    var.secret_value == null ? null : jsonencode(var.secret_value)
  )

  version_stages = ["AWSCURRENT"]
}

resource "aws_secretsmanager_secret_rotation" "secret" {
  count               = var.secret_rotation ? 1 : 0
  secret_id           = aws_secretsmanager_secret.secret.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.auto_rotation_days
  }
}
