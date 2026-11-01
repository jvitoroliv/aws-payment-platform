# kafka_schema.tf
# Part of the kafka_schema Terraform configuration module.

resource "aiven_kafka_schema" "tag_schema" {
  count = var.manage_schema ? 1 : 0

  compatibility_level = var.schema_compatability_level
  project             = data.aiven_project.finserv-project.project
  schema              = var.schema_configuration
  service_name        = local.source_cluster
  subject_name        = var.schema_subject_name
}
resource "aiven_kafka_schema" "tag_key_schema" {
  # Manage the key schema if the required variables are not null
  count = var.manage_schema == true && var.key_schema_configuration != null && var.key_schema_subject_name != null ? 1 : 0

  compatibility_level = var.schema_compatability_level
  project             = data.aiven_project.finserv-project.project
  schema              = var.key_schema_configuration
  service_name        = local.source_cluster
  subject_name        = var.key_schema_subject_name
}

moved {
  from = aiven_kafka_schema.tag_schema
  to   = aiven_kafka_schema.tag_schema[0]
}
