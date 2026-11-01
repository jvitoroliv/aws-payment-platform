# local.tf
# Manages local Terraform configuration resources.

locals {
  region            = var.region == "us-east-1"
  source_cluster    = local.region ? data.aiven_kafka.kafka_service_ue1.service_name : data.aiven_kafka.kafka_service_uw2.service_name
}