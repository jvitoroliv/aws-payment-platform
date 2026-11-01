# kafka_user.tf
# Part of the kafka_user Terraform configuration module.

resource "random_password" "tag_kafka_user_password" {
  length = 16
  special = false
}

resource "aiven_kafka_user" "tag_kafka_user" {
  password     = random_password.tag_kafka_user_password.result
  project      = data.aiven_project.finserv-project.project
  service_name = local.source_cluster
  username     = var.aiven_user
}

resource "aws_secretsmanager_secret" "tag_kafka_user_creds_name" {
  name = "${var.environment}_${var.aiven_user}"
}

resource "aws_secretsmanager_secret_version" "tag_kafka_user_creds_value" {
  secret_id = aws_secretsmanager_secret.tag_kafka_user_creds_name.id
  secret_string = random_password.tag_kafka_user_password.result
}

resource "aws_secretsmanager_secret" "tag_kafka_user_access_cert_name" {
  name = "${var.environment}_${var.aiven_user}_access_cert"
}

resource "aws_secretsmanager_secret_version" "tag_kafka_user_access_cert_value" {
  secret_id = aws_secretsmanager_secret.tag_kafka_user_access_cert_name.id
  secret_string = aiven_kafka_user.tag_kafka_user.access_cert
}

resource "aws_secretsmanager_secret" "tag_kafka_user_access_key_name" {
  name = "${var.environment}_${var.aiven_user}_access_key"
}

resource "aws_secretsmanager_secret_version" "tag_kafka_user_access_key_value" {
  secret_id = aws_secretsmanager_secret.tag_kafka_user_access_key_name.id
  secret_string = aiven_kafka_user.tag_kafka_user.access_key
}
