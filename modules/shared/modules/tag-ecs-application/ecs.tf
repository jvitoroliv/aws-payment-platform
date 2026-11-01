# ecs.tf
# Part of the ECS service definitions module.

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "aws_ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.1"

  # ECS Cluster
  cluster_name                = var.cluster_name
  cluster_configuration       = {}
  create_cloudwatch_log_group = false

  cluster_settings = {
    name  = "containerInsights"
    value = "disabled"
  }

  cluster_tags = {
    "Environment" = var.environment
    "NOSCHEDULE"  = "ECS"
  }

  # ECS Service
  services = {
    for service_key, service_values in var.services : service_key => merge(
      {
        # TAG default ECS Container Definitions, including Crowdstrike init and Datadog sidecar
        # The defaults can be overridden by explicitly defining them in var.services
        autoscaling_max_capacity           = 1
        autoscaling_min_capacity           = 1
        deployment_maximum_percent         = 100
        deployment_minimum_healthy_percent = 0
        desired_count                      = 1
        enable_ecs_managed_tags            = false
        runtime_platform                   = {}
        subnet_ids                         = var.aws_subnets

        container_definition_defaults = {
          cpu                                    = 0
          cloudwatch_log_group_retention_in_days = 0

          repository_credentials = {
            credentialsParameter = var.docker_secret_arn
          }
        }

        tags = {
          Application = service_key
          NOSCHEDULE  = "ECS"
        }

        volume = {
          crowdstrike-falcon-volume            = {}
          "crowdstrike-private-${service_key}" = {}
        }

        container_definitions = merge(
          {
            application = {
              essential = true
              image     = var.services[service_key].application_image, # application_image must be set for each service in var.services

              command = [
                "sh",
                "-c",
                var.services[service_key].application_run_command, # application_run_command must be set for each service in var.services
              ]

              dependencies = concat(
                try(!var.services[service_key].enable_datadog_sidecar, false) ? [] : [
                  {
                    condition     = "START"
                    containerName = "datadog"
                  },
                ],
                [
                  {
                    condition     = "COMPLETE"
                    containerName = "crowdstrike-falcon-init-container"
                  },
                ]
              )

              entrypoint = [
                "/tmp/CrowdStrike/rootfs/lib64/ld-linux-x86-64.so.2",
                "--library-path",
                "/tmp/CrowdStrike/rootfs/lib64",
                "/tmp/CrowdStrike/rootfs/bin/bash",
                "/tmp/CrowdStrike/rootfs/entrypoint-ecs.sh",
              ]

              environment = concat(
                [
                  # Always add these environment variables to the application container
                  {
                    name  = "AWS_REGION"
                    value = var.aws_region
                  },
                  {
                    name  = "ENVIRONMENT"
                    value = var.environment
                  },
                  {
                    name  = "SOURCE_SYSTEM"
                    value = "${var.environment}-tag"
                  },
                  {
                    name = "DD_ENV",
                    value = var.environment
                  },
                  {
                    name = "DD_SERVICE",
                    value = format("%s-%s", "tag", trim(service_key, "${var.environment}-"))
                  },
                  {
                    name = "DD_VERSION",
                    value = element(split(":", var.services[service_key].application_image), 1)
                  }
                ],
                [
                  # Append user defined env vars
                  for key, value in try(var.services[service_key].application_environment_variables, {}) : {
                    name  = key,
                    value = value
                  }
                ]
              )

              docker_labels = {
                "com.datadoghq.tags.env" = var.environment,
                "com.datadoghq.tags.service" = format("%s-%s", "tag", trim(service_key, "${var.environment}-")),
                "com.datadoghq.tags.version" = element(split(":", var.services[service_key].application_image), 1)
              }

              linux_parameters = {
                capabilities = {
                  add = [
                    "SYS_PTRACE",
                  ],
                  drop = []
                }
              }

              mount_points = [
                {
                  containerPath = "/tmp/CrowdStrike"
                  readOnly      = true
                  sourceVolume  = "crowdstrike-falcon-volume"
                },
                {
                  containerPath = "/tmp/CrowdStrike-private"
                  readOnly      = false
                  sourceVolume  = "crowdstrike-private-${service_key}"
                },
              ]

              # Create port mappings for each target group in the load balancer module and any additional port mappings defined in `application_port_mappings`
              port_mappings = concat(
                [
                  for group in try(var.services[service_key].application_target_groups, []) : {
                    # hostPort should be set to zero on EC2 to use an ephemeral port on the container instance, as is is fine for Fargate
                    containerPort = module.aws_alb.wrapper[group.load_balancer].target_groups[group.target_group].port
                    hostPort      = module.aws_alb.wrapper[group.load_balancer].target_groups[group.target_group].port
                    protocol      = module.aws_alb.wrapper[group.load_balancer].target_groups[group.target_group].protocol == "UDP" ? "udp" : "tcp"
                  }
                ],
                try(var.services[service_key].application_port_mappings, [])
              )

              secrets = concat(
                [
                  # Always add these secrets as environment variables to the application container
                  {
                    name      = "FALCONCTL_OPTS"
                    valueFrom = var.endpoint_security_cid_arg_arn
                  }
                ],
                [
                  # Append user defined secrets
                  for key, value in try(var.services[service_key].application_secret_arns, {}) : {
                    name      = key,
                    valueFrom = value
                  }
                ]
              )
            }
          },

          {
            crowdstrike-falcon-init-container = {
              essential = false
              image     = "registry.example.io/crowdstrike-docker-prod-federated-us/falcon-container-sensor:${var.crowdstrike_sensor_version}"
              user      = "0:0"

              entrypoint = [
                "/bin/bash",
                "-c",
                "chmod u+rwx /tmp/CrowdStrike && mkdir /tmp/CrowdStrike/rootfs && cp -r /bin /etc /lib64 /usr /entrypoint-ecs.sh /tmp/CrowdStrike/rootfs && chmod -R a=rX /tmp/CrowdStrike && chmod -R a=rwX /tmp/CrowdStrike-private-${service_key}",
              ]

              environment = [
                # Append user defined env vars
                for key, value in try(var.services[service_key].crowdstrike_environment_variables, {}) : {
                  name  = key
                  value = value
                }
              ]

              mount_points = [
                {
                  containerPath = "/tmp/CrowdStrike"
                  readOnly      = false
                  sourceVolume  = "crowdstrike-falcon-volume"
                },
                {
                  containerPath = "/tmp/CrowdStrike-private-${service_key}"
                  readOnly      = false
                  sourceVolume  = "crowdstrike-private-${service_key}"
                },
              ]
            }
          },

          try(!var.services[service_key].enable_datadog_sidecar, false) ? {} : {
            datadog = {
              essential = true
              image     = var.datadog_image

              # The Datadog agent currently modifies files in the container root filesystem so readonly causes it to crash
              # Related Github may be resolved in future: https://github.com/DataDog/datadog-agent/issues/15127
              readonly_root_filesystem = false

              environment = concat(
                [
                  # Always add these environment variables to the datadog container
                  {
                    name  = "DD_DOGSTATSD_NON_LOCAL_TRAFFIC"
                    value = "true"
                  },
                  {
                    name = "DD_DOGSTATSD_TAGS"
                    value = jsonencode([
                      "environment:${var.environment}",
                      "fargate:true",
                    ])
                  },
                  {
                    name  = "DD_TAGS"
                    value = "environment:${var.environment} fargate:true"
                  },
                  {
                    name  = "ECS_FARGATE"
                    value = "true"
                  },
                  {
                    name  = "ENVIRONMENT"
                    value = var.environment
                  },
                  {
                    name = "DD_ENV",
                    value = var.environment
                  },
                  {
                    name = "DD_SERVICE",
                    value = format("%s-%s", "tag", trim(service_key, "${var.environment}-"))
                  },
                  {
                    name = "DD_VERSION",
                    value = element(split(":", var.services[service_key].application_image), 1)
                  },
                ],
                [
                  # Append user defined env vars
                  for key, value in try(var.services[service_key].datadog_environment_variables, {}) : {
                    name  = key
                    value = value
                  }
                ]
              )

              docker_labels = {
                "com.datadoghq.tags.env" = var.environment,
                "com.datadoghq.tags.service" = format("%s-%s", "tag", trim(service_key, "${var.environment}-")),
                "com.datadoghq.tags.version" = element(split(":", var.services[service_key].application_image), 1)
              }

              # Create default port 8125 UDP Datadog agent port mapping plus any additional port mappings defined in `datadog_port_mappings`
              port_mappings = concat(
                [
                  {
                    containerPort = 8125
                    hostPort      = 8125
                    protocol      = "udp"
                  },
                ],
                try(var.services[service_key].datadog_port_mappings, [])
              )

              secrets = [
                {
                  name      = "DD_API_KEY"
                  valueFrom = var.datadog_api_key_secret_arn
                },
              ]
            }
          }
        )
      },

      # Explictly defined values
      # Defaults from above are merged with explicit values of each service in var.services
      service_values,

      # Appended values
      # Due to Terraform not having a deepmerge() function, the below values append themselves to explictly defined values in var.services
      {
        # Enable specifying by name the target groups from the load balancer module to attach to the service in the 'application_target_groups' attribute
        # Externally managed load balancers can still be attached in the usual way via the 'load_balancer' attribute
        load_balancer = merge(
          {
            for group in try(var.services[service_key].application_target_groups, []) : group.target_group => {
              container_name   = "application"
              container_port   = module.aws_alb.wrapper[group.load_balancer].target_groups[group.target_group].port
              target_group_arn = module.aws_alb.wrapper[group.load_balancer].target_groups[group.target_group].arn
            }
          },
          try(var.services[service_key].load_balancer, {})
        )

        # Create ingress security group rules for each target group in the load balancer module specified by the 'application_target_groups' attribute
        security_group_rules = merge(
          {
            for group in try(var.services[service_key].application_target_groups, []) : "ingress_alb_${replace(group.load_balancer,"-","_")}_tg_${replace(group.target_group,"-","_")}" => {
              from_port                = module.aws_alb.wrapper[group.load_balancer].target_groups[group.target_group].port
              protocol                 = module.aws_alb.wrapper[group.load_balancer].target_groups[group.target_group].protocol == "UDP" ? "udp" : "tcp"
              source_security_group_id = module.aws_alb.wrapper[group.load_balancer].security_group_id
              to_port                  = module.aws_alb.wrapper[group.load_balancer].target_groups[group.target_group].port
              type                     = "ingress"
            }
          },
          try(var.services[service_key].security_group_rules, {})
        )
      }
    )
  }
}