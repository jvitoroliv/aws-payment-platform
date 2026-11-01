aiven_kafka_user = "tag_stage_aiven_accounts_receivable_user"
aiven_kafka_topic_acls = {
  "configuration.funding.entity-groups" = {
    topic_permission           = "read"
    schema_registry_permission = "schema_registry_read"
  }
  "transaction.funding.entity-groups" = {
    topic_permission           = "read"
    schema_registry_permission = "schema_registry_read"
  }
}
aiven_project          = "stage"
aws_vpc_id             = "vpc-0example000000001"
environment            = "stage"
region                 = "us-east-1"
secondary_region       = "us-west-2"
task_definition_cpu    = 2048
task_definition_memory = 4096
