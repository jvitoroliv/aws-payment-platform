# secret.tf
# Manages secret Terraform configuration resources.

resource "aws_secretsmanager_secret" "secret" {
  #ts:skip=AWS.SecretsManagerSecret.DP.MEDIUM.0036 No need to KMS encrypt secret when running in localstack
  name = "${var.environment}-${var.secret_id}"
}
resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.secret_value
}
