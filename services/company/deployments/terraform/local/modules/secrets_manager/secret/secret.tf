# secret.tf
# Part of the secret Terraform configuration module.

resource "aws_secretsmanager_secret" "secret" {
  name = "${var.environment}-${var.secret_id}"
}
resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.secret_value
}