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
  key_schema_configuration     = file("${path.module}/../../../internal/tag-non-posted-exception-create-key.avsc")
  key_schema_subject_name      = "${var.environment == "dev" ? "dev-" : ""}company.issuing.processing.NonPostedException-key"
  manage_schema                = (var.region == "us-east-1") # Don't create Kafka Schema in us-west-2 as it is replicated from us-east-1
  region                       = var.region
  schema_compatability_level   = "BACKWARD"
  schema_configuration         = file("${path.module}/../../../internal/tag-non-posted-exception-create.avsc") # Use templatefile() when parameterization is added
  schema_subject_name          = "${var.environment == "dev" ? "dev-" : ""}company.issuing.processing.NonPostedException-value"
  topic_cleanup_policy         = var.topic_cleanup_policy
  topic_partition              = var.topic_partition
  topic_replication            = var.topic_replication
  topic_retention_time         = var.topic_retention_time
  topic_termination_protection = var.topic_termination_protection
  topic_title                  = var.topic_title
}

module "tag_ecs_terraform" {
  source                     = "git::https://github.com/example-org/shared-terraform//modules/tag-ecs-application?ref=tag-ecs-application-1.1"
  aws_region                 = var.region
  aws_subnets                = data.aws_subnets.private.ids
  aws_vpc_id                 = var.aws_vpc_id
  cluster_name               = "${var.environment}-${var.region}-non-posted-exceptions"
  endpoint_security_cid_arg_arn    = "${data.aws_secretsmanager_secret.crowdstrike.arn}:endpoint_security_cid::"
  datadog_api_key_secret_arn = "${data.aws_secretsmanager_secret.datadog_api_key_secret.arn}:datadog-api-key::"
  docker_secret_arn          = data.aws_secretsmanager_secret.artifactory.arn
  environment                = var.environment
  log_lambda_arn             = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn
  services = {
    "${var.environment}-exception-producer" = {
      application_image                        = "registry.example.io/tag-docker-${var.environment == "prod" ? "prod" : "nonprod"}-federated-us/tag/exception-producer:${var.app_version}"
      application_run_command                  = "exec /app/exception-producer"
      application_log_subscription_filter_name = "${var.environment}-exception-producer"
      autoscaling_max_capacity                 = var.autoscaling_max_capacity
      autoscaling_min_capacity                 = var.autoscaling_min_capacity
      desired_count                            = var.autoscaling_min_capacity # This is only utilized when the ECS Service is first created. Autoscaling will take over after that.

      security_group_rules = {
        egress_aiven = {
          cidr_blocks = ["0.0.0.0/0"]
          description = "Aiven"
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
          description = "Mongo"
          from_port   = 27017
          protocol    = "tcp"
          to_port     = 27017
          type        = "egress"
        }
      }

      tasks_iam_role_statements = [
        {
          actions = ["secretsmanager:GetSecretValue"]
          effect  = "Allow"
          resources = [
            "arn:aws:secretsmanager:*:*:secret:*"
          ]
        }
      ]
    }
  }
}
