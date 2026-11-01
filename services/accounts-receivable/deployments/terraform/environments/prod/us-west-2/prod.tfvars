aiven_kafka_user = "tag_prod_aiven_accounts_receivable_user"
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
aiven_project          = "prod"
aws_vpc_id             = "vpc-0example000000001"
environment            = "prod"
region                 = "us-west-2"
secondary_region       = "us-east-1"
task_definition_cpu    = 2048
task_definition_memory = 4096
