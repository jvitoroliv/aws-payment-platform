# kafka_acl.tf
# Manages kafka_acl Terraform configuration resources.

resource "aiven_kafka_acl" "tag_acl" {
  permission   = var.acl_permission
  project      = data.aiven_project.finserv-project.id
  service_name = local.source_cluster
  topic        = aiven_kafka_topic.tag_topic.topic_name
  username     = aiven_kafka_user.tag_kafka_user.username
}

resource "aiven_kafka_schema_registry_acl" "schema_reg_acl" {
  permission   = "schema_registry_write"
  project      = data.aiven_project.finserv-project.id
  service_name = local.source_cluster
  resource     = "Subject:${aiven_kafka_topic.tag_topic.topic_name}*"
  username     = aiven_kafka_user.tag_kafka_user.username
}