# main.tf
# Manages primary resource definitions resources.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "tag_kafka_terraform" {
  source                       = "git::https://github.com/example-org/ps-tag-kafka.git//terraform?ref=v2.2.2"
  acl_permission               = "admin"
  aiven_project                = var.aiven_project
  aiven_user                   = var.aiven_user
  environment                  = var.environment
  manage_schema                = var.region == "us-east-1" # Don't create the Kafka Schema in us-west-2 as it is replicated from us-east-1
  region                       = var.region
  schema_compatability_level   = "BACKWARD"
  schema_configuration         = file("${path.module}/../../../internal/tag-company-create-update.avsc")
  key_schema_configuration     = file("${path.module}/../../../internal/tag-company-create-update-key.avsc")
  schema_subject_name          = "${var.environment == "dev" ? "dev-" : ""}issuing.account-management.company-value"
  key_schema_subject_name      = "${var.environment == "dev" ? "dev-" : ""}issuing.account-management.company-key"
  topic_cleanup_policy         = var.topic_cleanup_policy
  topic_partition              = var.topic_partition
  topic_replication            = var.topic_replication
  topic_retention_time         = var.topic_retention_time
  topic_termination_protection = var.topic_termination_protection
  topic_title                  = var.topic_title
}

module "tag_ecs_terraform" {
  source = "github.com/example-org/shared-terraform//modules/tag-ecs-application?ref=tag-ecs-application-1.1"

  aws_region                 = var.region
  aws_subnets                = data.aws_subnets.private.ids
  aws_vpc_id                 = var.aws_vpc_id
  cluster_name               = "${var.environment}-${var.region}-company"
  endpoint_security_cid_arg_arn    = "${data.aws_secretsmanager_secret.endpoint_security_cid_arg.arn}:endpoint_security_cid::" # "endpoint_security_cid" is the JSON key within the secret
  datadog_api_key_secret_arn = "${data.aws_secretsmanager_secret.datadog_api_key.arn}:datadog-api-key::"     # "datadog-api-key" is the JSON key within the secret
  docker_secret_arn          = data.aws_secretsmanager_secret.artifactory.arn
  environment                = var.environment
  log_lambda_arn             = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn

  services = {
    "${var.environment}-company-producer" = {
      application_image                        = "registry.example.io/tag-docker-${local.nonprod_or_prod}-federated-us/tag/company-producer:${var.app_version}"
      application_run_command                  = "exec /app/company-producer"
      application_log_subscription_filter_name = "${var.environment}-company-producer"
      autoscaling_max_capacity                 = var.autoscaling_max_capacity
      autoscaling_min_capacity                 = var.autoscaling_min_capacity
      desired_count                            = var.autoscaling_min_capacity # This is only utilized when the ECS Service is first created. Autoscaling will take over after that.
      cpu                                      = var.task_definition_cpu
      memory                                   = var.task_definition_memory

      autoscaling_policies = {} # No autoscaling for now

      security_group_rules = {
        egress_aiven = {
          cidr_blocks = ["0.0.0.0/0"]
          description = "Aiven Open Ports"
          from_port   = 10000
          protocol    = "tcp"
          to_port     = 65535
          type        = "egress"
        }
        egress_internet = {
          cidr_blocks = ["0.0.0.0/0"]
          description = "Internet"
          from_port   = 443
          protocol    = "tcp"
          to_port     = 443
          type        = "egress"
        }
        egress_mongodb = {
          cidr_blocks = ["0.0.0.0/0"]
          description = "MONGO"
          from_port   = 27017
          protocol    = "tcp"
          to_port     = 27017
          type        = "egress"
        }
      }

      tasks_iam_role_statements = [
        # Allow the application to retrieve any secret from Secrets Manager
        {
          actions   = ["secretsmanager:GetSecretValue"]
          effect    = "Allow"
          resources = ["arn:aws:secretsmanager:*:*:secret:*"]
        }
      ]
    }
  }
}
