# ecs.tf
# Manages ECS service definitions resources.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "tag_ecs_terraform" {
  source = "github.com/example-org/shared-terraform//modules/tag-ecs-application?ref=tag-ecs-application-1.1"

  aws_region                 = var.region
  aws_subnets                = data.aws_subnets.private.ids
  aws_vpc_id                 = var.aws_vpc_id
  cluster_name               = "${var.environment}-${var.region}-accounts-receivable"
  endpoint_security_cid_arg_arn    = local.endpoint_security_cid_arg_secret_arn
  datadog_api_key_secret_arn = local.datadog_api_key_secret_arn
  docker_secret_arn          = data.aws_secretsmanager_secret.artifactory.arn
  environment                = var.environment
  log_lambda_arn             = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn

  services = {
    "${var.environment}-ar-funding-group-consumer" = {
      application_image                        = "registry.example.io/tag-docker-${var.environment == "prod" ? "prod" : "nonprod"}-federated-us/tag/accounts-receivable-funding-group-consumer:${var.app_version}"
      application_run_command                  = "exec /app/cmd/funding-group-consumer/main"
      application_log_subscription_filter_name = "${var.environment}-accounts-receivable-funding-group-consumer"
      autoscaling_max_capacity                 = 1
      autoscaling_min_capacity                 = 1
      cpu                                      = var.task_definition_cpu
      memory                                   = var.task_definition_memory

      application_environment_variables = {
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317/"
      }

      autoscaling_policies = {} # No autoscaling for now

      datadog_environment_variables = {
        DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT = "0.0.0.0:4317" # Configure the Datadog Agent to ingest via GPRC
        DD_USE_DOGSTATSD                                = "false"        # Disable DogStatsD as it is not currently being used
      }

      datadog_port_mappings = [
        # Expose the Datadog OTLP GPRC ingest port
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
        }
      ]

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
