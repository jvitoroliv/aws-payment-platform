# kafka.tf
# Manages kafka Terraform configuration resources.

data "aiven_kafka_user" "kafka_user" {
  for_each = toset(var.aiven_kafka_users)

  project      = data.aiven_project.aiven_project.project
  service_name = data.aiven_kafka.kafka_service.service_name
  username     = each.key
}

resource "aws_secretsmanager_secret" "kafka_password" {
  #ts:skip=AWS.SecretsManagerSecret.DP.MEDIUM.0036 Ignore non-CMK KMS encryption for now
  for_each = toset(var.aiven_kafka_users)

  name = "${var.environment}_${each.key}_aiven_password"
}

resource "aws_secretsmanager_secret_version" "kafka_password" {
  for_each = toset(var.aiven_kafka_users)

  secret_id     = aws_secretsmanager_secret.kafka_password[each.key].id
  secret_string = data.aiven_kafka_user.kafka_user[each.key].password
}

resource "aws_secretsmanager_secret" "kafka_user_access_cert" {
  #ts:skip=AWS.SecretsManagerSecret.DP.MEDIUM.0036 Ignore non-CMK KMS encryption for now
  for_each = toset(var.aiven_kafka_users)

  name = "${var.environment}_${each.key}_aiven_access_cert"
}

resource "aws_secretsmanager_secret_version" "kafka_user_access_cert" {
  for_each = toset(var.aiven_kafka_users)

  secret_id     = aws_secretsmanager_secret.kafka_user_access_cert[each.key].id
  secret_string = data.aiven_kafka_user.kafka_user[each.key].access_cert
}

resource "aws_secretsmanager_secret" "kafka_user_access_key" {
  #ts:skip=AWS.SecretsManagerSecret.DP.MEDIUM.0036 Ignore non-CMK KMS encryption for now
  for_each = toset(var.aiven_kafka_users)

  name = "${var.environment}_${each.key}_aiven_access_key"
}

resource "aws_secretsmanager_secret_version" "kafka_user_access_key" {
  for_each = toset(var.aiven_kafka_users)

  secret_id     = aws_secretsmanager_secret.kafka_user_access_key[each.key].id
  secret_string = data.aiven_kafka_user.kafka_user[each.key].access_key
}
