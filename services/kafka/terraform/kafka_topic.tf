# kafka_topic.tf
# Manages kafka_topic Terraform configuration resources.

resource "aiven_kafka_topic" "tag_topic" {
  partitions              = var.topic_partition
  project                 = data.aiven_project.finserv-project.project
  replication             = var.topic_replication
  service_name            = local.source_cluster
  termination_protection  = var.topic_termination_protection
  topic_name              = var.topic_title
  config {
    cleanup_policy      = var.topic_cleanup_policy
    min_insync_replicas = var.topic_replication
    retention_ms        = var.topic_retention_time
  }
}
