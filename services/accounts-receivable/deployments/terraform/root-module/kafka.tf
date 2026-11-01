# kafka.tf
# Part of the kafka Terraform configuration module.

resource "random_password" "kafka_user_password" {
  length  = 16
  special = false
}

resource "aiven_kafka_user" "kafka_user" {
  password     = random_password.kafka_user_password.result
  project      = data.aiven_project.aiven_project.project
  service_name = data.aiven_kafka.kafka_service.service_name
  username     = var.aiven_kafka_user
}

resource "aws_secretsmanager_secret" "kafka_password" {
  #ts:skip=AWS.SecretsManagerSecret.DP.MEDIUM.0036 Ignore non-CMK KMS encryption for now
  name = "${var.environment}_${replace(var.region, "-", "_")}_${var.aiven_kafka_user}_password"

  replica {
    region = var.secondary_region
  }
}

resource "aws_secretsmanager_secret_version" "kafka_password" {
  secret_id     = aws_secretsmanager_secret.kafka_password.id
  secret_string = random_password.kafka_user_password.result
}

resource "aws_secretsmanager_secret" "kafka_user_access_cert" {
  #ts:skip=AWS.SecretsManagerSecret.DP.MEDIUM.0036 Ignore non-CMK KMS encryption for now
  name = "${var.environment}_${replace(var.region, "-", "_")}_${var.aiven_kafka_user}_access_cert"

  replica {
    region = var.secondary_region
  }
}

resource "aws_secretsmanager_secret_version" "kafka_user_access_cert" {
  secret_id     = aws_secretsmanager_secret.kafka_user_access_cert.id
  secret_string = aiven_kafka_user.kafka_user.access_cert
}

resource "aws_secretsmanager_secret" "kafka_user_access_key" {
  #ts:skip=AWS.SecretsManagerSecret.DP.MEDIUM.0036 Ignore non-CMK KMS encryption for now
  name = "${var.environment}_${replace(var.region, "-", "_")}_${var.aiven_kafka_user}_access_key"

  replica {
    region = var.secondary_region
  }
}

resource "aws_secretsmanager_secret_version" "kafka_user_access_key" {
  secret_id     = aws_secretsmanager_secret.kafka_user_access_key.id
  secret_string = aiven_kafka_user.kafka_user.access_key
}

resource "aiven_kafka_acl" "kafka_acl" {
  for_each = var.aiven_kafka_topic_acls

  permission   = each.value.topic_permission
  project      = data.aiven_project.aiven_project.id
  service_name = data.aiven_kafka.kafka_service.service_name
  topic        = each.key
  username     = aiven_kafka_user.kafka_user.username
}

resource "aiven_kafka_schema_registry_acl" "schema_registry_acl" {
  for_each = var.aiven_kafka_topic_acls

  permission   = each.value.schema_registry_permission
  project      = data.aiven_project.aiven_project.id
  service_name = data.aiven_kafka.kafka_service.service_name
  resource     = "Subject:${each.key}*"
  username     = aiven_kafka_user.kafka_user.username
}
