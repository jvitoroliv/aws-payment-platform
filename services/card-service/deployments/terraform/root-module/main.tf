# main.tf
# Part of the primary resource definitions module.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "allowlist" {
  source = "../modules/tag-allowlist"
  allowlists = jsondecode(
  file("${path.module}/../configuration/allowlists/${var.environment}.json"))
  cidrs_blocks_by_name = jsondecode(
  file("${path.module}/../configuration/allowlists/cidrs_blocks_by_name.json"))

}

# Shared module — changes here affect all consumers. Semver applies.
module "ecs_application" {
  source = "github.com/example-org/shared-terraform//modules/tag-ecs-application?ref=tag-ecs-application-1.1"

  aws_region                 = var.aws_region
  aws_subnets                = data.aws_subnets.private.ids
  aws_vpc_id                 = var.aws_vpc_id
  cluster_name               = "${var.environment}-${var.aws_region}-card-service"
  endpoint_security_cid_arg_arn    = local.endpoint_security_cid_arg_secret_arn
  datadog_api_key_secret_arn = local.datadog_secret_arn
  docker_secret_arn          = data.aws_secretsmanager_secret.artifactory.arn
  environment                = var.environment
  log_lambda_arn             = data.terraform_remote_state.shared.outputs.logconsumer_lambda_arn

  load_balancers = {
    "${var.environment}-${var.aws_region}-card-service" = {
      drop_invalid_header_fields = false
      enable_deletion_protection = false
      internal                   = true
      name                       = "${var.environment}-${local.aws_region_short}-card-service" # Must be less than 32 chars
      security_group_name        = "${var.environment}-${var.aws_region}-card-service-alb"
      subnets                    = data.aws_subnets.private.ids
      type                       = "internal"
      vpc_id                     = var.aws_vpc_id

      access_logs = {
        bucket  = data.terraform_remote_state.shared.outputs.access_log_bucket_name
        enabled = true
        prefix  = "${var.environment}-${var.aws_region}-card-service-internal-alb-access-logs"
      }

      listeners = {
        https = {
          certificate_arn = var.web_ssl_cert_arn
          port            = 443
          protocol        = "HTTPS"
          ssl_policy      = var.load_balancer_ssl_policy

          forward = {
            target_group_key = "api-internal"
          }
        }
      }

      route53_records = {
        service-api = {
          zone_id = var.dns_zone_id
          name    = var.card_service_api.endpoint_url
          type    = "A"
        }
      }

      security_group_ingress_rules = {
        for cidr_block in module.allowlist.api_internal_allowlist_cidr_blocks : "https_from_${cidr_block}" => {
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          description = "HTTPS traffic from ${cidr_block}"
          cidr_ipv4   = cidr_block
        }
      }

      security_group_egress_rules = {
        all_internal = {
          ip_protocol = "-1"
          cidr_ipv4   = local.cidr_vpc_local
        }
      }

      tags = {
        Service     = "card-service-api"
      }

      target_groups = {
        api-internal = {
          create_attachment = false # This is set to false because the targets are managed by ECS
          name              = "${var.environment}-card-service-api"
          port              = 8001
          protocol          = "HTTP"
          target_type       = "ip"
          vpc_id            = var.aws_vpc_id

          health_check = {
            enabled             = true
            healthy_threshold   = 2
            interval            = 10
            matcher             = "200"
            path                = "/api/card-service/health-check"
            port                = "traffic-port"
            protocol            = "HTTP"
            timeout             = 5
            unhealthy_threshold = 2
          }
        }
      }

      timeouts = {
        create = "30m"
        delete = "30m"
      }
    }
  }

  services = {
    "${var.environment}-card-service-api" = {
      application_image                  = "registry.example.io/tag-docker-${var.environment == "prod" ? "prod" : "nonprod"}-federated-us/tag/card-service-api:${var.app_version}"
      application_run_command            = "exec /app/card-service-api"
      autoscaling_max_capacity           = var.card_service_api.autoscaling_max_capacity
      autoscaling_min_capacity           = var.card_service_api.autoscaling_min_capacity
      cpu                                = var.card_service_api.task_definition_cpu
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 100
      desired_count                      = var.card_service_api.autoscaling_min_capacity
      memory                             = var.card_service_api.task_definition_memory

      application_log_subscription_filter_name = "${var.environment}-card-service-api"

      application_target_groups = [
        {
          load_balancer = "${var.environment}-${var.aws_region}-card-service"
          target_group  = "api-internal"
        }
      ]

      autoscaling_policies = {
        "memory-utilization" = {
          policy_type = "TargetTrackingScaling"

          target_tracking_scaling_policy_configuration = {
            disable_scale_in   = false
            scale_in_cooldown  = 300
            scale_out_cooldown = 300
            target_value       = 100

            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageMemoryUtilization"
            }
          }
        }
      }

      application_environment_variables = {
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317/"
      }

      datadog_environment_variables = {
        DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT = "0.0.0.0:4317" # Configure the Datadog Agent to ingest via GPRC
        DD_USE_DOGSTATSD                                = "false"        # Disable DogStatsD as it is not currently being used
      }

      datadog_port_mappings = [
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
        }
      ]

      security_group_rules = merge(
        local.hsm_sg_rule_json,
        {
          # Ingress rule for the ALB is created automatically by the tag-ecs-application module
          egress_all_https = {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"] //TODO: This would seem to need to change
            type        = "egress"
          }
          egress_internal_postgres = {
            from_port = 5432
            to_port   = 5432
            protocol  = "tcp"
            cidr_blocks = [
              var.cidr_vpc_ue1,
              var.cidr_vpc_uw2,
            ]
            type = "egress"
          }
          egress_internal_dns = {
            from_port   = 53
            to_port     = 53
            protocol    = "udp"
            cidr_blocks = [local.cidr_vpc_local]
            type        = "egress"
          }
        }
      )

      tasks_iam_role_statements = [
        # Allow the application to retrieve any secret from Secrets Manager
        {
          actions   = ["secretsmanager:GetSecretValue"]
          effect    = "Allow"
          resources = ["arn:aws:secretsmanager:*:*:secret:*"]
        }
      ]

      triggers = {
        # Trigger a new deployment even when there are no changes
        redeployment = plantimestamp()
      }
    }
    "${var.environment}-card-service-db-datadog-agent" = {
      application_image                  = "registry.example.io/tag-docker-${var.environment == "prod" ? "prod" : "nonprod"}-federated-us/tag/card-service-db-datadog-agent:${var.app_version}"
      application_run_command            = "exec /bin/entrypoint.sh"
      autoscaling_max_capacity           = var.card_service_db_datadog_agent.autoscaling_max_capacity
      autoscaling_min_capacity           = var.card_service_db_datadog_agent.autoscaling_min_capacity
      cpu                                = var.card_service_db_datadog_agent.task_definition_cpu
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 100
      desired_count                      = 1
      enable_datadog_sidecar             = false # Remove the Datadog sidecar container as it conflicts ports with application Datadog container
      memory                             = var.card_service_db_datadog_agent.task_definition_memory

      application_log_subscription_filter_name = "${var.environment}-card-service-db-datadog-agent"

      application_environment_variables = {
        DD_CLOUD_PROVIDER_METADATA = "aws"
        DD_CONFD_PATH              = "/config/${var.environment}/${var.aws_region}"
      }

      application_secret_arns = {
        DD_API_KEY = local.datadog_secret_arn
      }

      autoscaling_policies = {}

      security_group_rules = {
        egress_all_https = {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          type        = "egress"
        }
        egress_internal_postgres = {
          from_port = 5432
          to_port   = 5432
          protocol  = "tcp"
          cidr_blocks = [
            var.cidr_vpc_ue1,
            var.cidr_vpc_uw2,
          ]
          type = "egress"
        }
        egress_internal_dns = {
          from_port   = 53
          to_port     = 53
          protocol    = "udp"
          cidr_blocks = [local.cidr_vpc_local]
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

      triggers = {
        # Trigger a new deployment even when there are no changes
        redeployment = plantimestamp()
      }
    }
    "${var.environment}-card-service-dispatcher" = {
      application_image                  = "registry.example.com/tag-docker-${var.environment == "prod" ? "prod" : "nonprod"}-federated-us/tag/card-dispatcher:${var.app_version}"
      application_run_command            = "exec /app/card-dispatcher"
      autoscaling_max_capacity           = var.card_service_dispatcher.autoscaling_max_capacity
      autoscaling_min_capacity           = var.card_service_dispatcher.autoscaling_min_capacity
      cpu                                = var.card_service_dispatcher.task_definition_cpu
      deployment_maximum_percent         = 100
      deployment_minimum_healthy_percent = 0
      desired_count                      = var.card_service_dispatcher.autoscaling_min_capacity
      memory                             = var.card_service_dispatcher.task_definition_memory

      application_log_subscription_filter_name = "${var.environment}-card-service-dispatcher"

      autoscaling_policies = {
        "memory-utilization" = {
          policy_type = "TargetTrackingScaling"

          target_tracking_scaling_policy_configuration = {
            disable_scale_in   = false
            scale_in_cooldown  = 300
            scale_out_cooldown = 300
            target_value       = 100

            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageMemoryUtilization"
            }
          }
        }
      }

      application_environment_variables = {
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317/"
      }

      datadog_environment_variables = {
        DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT = "0.0.0.0:4317" # Configure the Datadog Agent to ingest via GPRC
        DD_USE_DOGSTATSD                                = "false"        # Disable DogStatsD as it is not currently being used
      }

      datadog_port_mappings = [
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
        }
      ]

      security_group_rules = {
        egress_all_https = {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"] //TODO: This would seem to need to change
          type        = "egress"
        }
        egress_internal_postgres = {
          from_port = 5432
          to_port   = 5432
          protocol  = "tcp"
          cidr_blocks = [
            var.cidr_vpc_ue1,
            var.cidr_vpc_uw2,
          ]
          type = "egress"
        }
        egress_internal_dns = {
          from_port   = 53
          to_port     = 53
          protocol    = "udp"
          cidr_blocks = [local.cidr_vpc_local]
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

      triggers = {
        # Trigger a new deployment even when there are no changes
        redeployment = plantimestamp()
      }
    }
    "${var.environment}-card-service-company-consumer" = {
      application_image                  = "registry.example.io/tag-docker-${var.environment == "prod" ? "prod" : "nonprod"}-federated-us/tag/card-service-company-consumer:${var.app_version}"
      application_run_command            = "exec /app/company-consumer"
      autoscaling_max_capacity           = var.card_service_company_consumer.autoscaling_max_capacity
      autoscaling_min_capacity           = var.card_service_company_consumer.autoscaling_min_capacity
      cpu                                = var.card_service_company_consumer.task_definition_cpu
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 100
      desired_count                      = var.card_service_company_consumer.autoscaling_min_capacity
      memory                             = var.card_service_company_consumer.task_definition_memory

      application_log_subscription_filter_name = "${var.environment}-card-service-company-consumer"

      application_environment_variables = {
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317/"
      }

      autoscaling_policies = {}

      datadog_environment_variables = {
        DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT = "0.0.0.0:4317" # Configure the Datadog Agent to ingest via GPRC
        DD_USE_DOGSTATSD                                = "false"        # Disable DogStatsD as it is not currently being used
      }

      datadog_port_mappings = [
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
        }
      ]

      security_group_rules = {
        egress_all_aiven = {
          from_port   = 10000
          to_port     = 65535
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          type        = "egress"
        }
        egress_all_https = {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          type        = "egress"
        }
        egress_internal_postgres = {
          from_port = 5432
          to_port   = 5432
          protocol  = "tcp"
          cidr_blocks = [
            var.cidr_vpc_ue1,
            var.cidr_vpc_uw2,
          ]
          type = "egress"
        }
        egress_internal_dns = {
          from_port   = 53
          to_port     = 53
          protocol    = "udp"
          cidr_blocks = [local.cidr_vpc_local]
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

      triggers = {
        # Trigger a new deployment even when there are no changes
        redeployment = plantimestamp()
      }
    }
    "${var.environment}-card-producer" = {
      application_image                  = "registry.example.io/tag-docker-${var.environment == "prod" ? "prod" : "nonprod"}-federated-us/tag/card-producer:${var.app_version}"
      application_run_command            = "exec /app/card-producer"
      autoscaling_max_capacity           = var.card_service_producer.autoscaling_max_capacity
      autoscaling_min_capacity           = var.card_service_producer.autoscaling_min_capacity
      cpu                                = var.card_service_producer.task_definition_cpu
      deployment_maximum_percent         = 100
      deployment_minimum_healthy_percent = 0
      desired_count                      = var.card_service_producer.autoscaling_min_capacity
      memory                             = var.card_service_producer.task_definition_memory

      application_log_subscription_filter_name = "${var.environment}-card-producer"

      application_environment_variables = {
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317/"
      }

      autoscaling_policies = {}

      datadog_environment_variables = {
        DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT = "0.0.0.0:4317" # Configure the Datadog Agent to ingest via GPRC
        DD_USE_DOGSTATSD                                = "false"        # Disable DogStatsD as it is not currently being used
      }

      datadog_port_mappings = [
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
        }
      ]

      security_group_rules = merge(
        local.hsm_sg_rule_json,
        {
          egress_all_aiven = {
            from_port   = 10000
            to_port     = 65535
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            type        = "egress"
          }
          egress_all_https = {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            type        = "egress"
          }
          egress_internal_postgres = {
            from_port = 5432
            to_port   = 5432
            protocol  = "tcp"
            cidr_blocks = [
              var.cidr_vpc_ue1,
              var.cidr_vpc_uw2,
            ]
            type = "egress"
          }
          egress_internal_dns = {
            from_port   = 53
            to_port     = 53
            protocol    = "udp"
            cidr_blocks = [local.cidr_vpc_local]
            type        = "egress"
          }
        }
      )

      tasks_iam_role_statements = [
        # Allow the application to retrieve any secret from Secrets Manager
        {
          actions   = ["secretsmanager:GetSecretValue"]
          effect    = "Allow"
          resources = ["arn:aws:secretsmanager:*:*:secret:*"]
        }
      ]

      triggers = {
        # Trigger a new deployment even when there are no changes
        redeployment = plantimestamp()
      }
    }
  }
}
