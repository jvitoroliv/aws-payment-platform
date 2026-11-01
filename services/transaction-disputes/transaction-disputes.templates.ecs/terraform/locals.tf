# locals.tf
# Part of the local value computations module.

# Static variables
locals {
  app_name                               = "INSERT_APP_NAME"    # Logical name of the application. Should be equal to the name of subfolder used by the application in the repository.
  long_app_name                          = "INSERT_APP_NAME"    # Applicaiton name replacing periods with underscores. This is needed in order to create some AWS resources that have special character constraints in the resource name.
  datadog_service_name                   = "INSERT_APP_NAME"    # Applicaiton name replacing periods with underscores. This is needed in order to create some AWS resources that have special character constraints in the resource name.
  short_app_name                         = "INSERT_APP_NAME"                                                   # Short version of the application name. This is needed in order to create some AWS resources that have length constraints in the resource name.
  ecs_cluster_name                       = "platform-services"                                                                           # The name of the AWS ECS Cluster in the PLATFORM-SERVICES accounts
  ecr_repository_name                    = "platform-services-ecr"                                                                       # The name of the AWS ECR cluster in the PLATFORM-SERVICES accounts
  ecs_desired_count                      = 1                                                                                  # Default number of instances to launch during application deployment
  ecs_deployment_minimum_healthy_percent = 100                                                                                 # Lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment.
  ecs_deployment_maximum_percent         = 300                                                                                # Upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment.
  ecs_scale_down_cron                    = "cron(0 0 * * ? *)"                                                                # Every day at 7PM Eastern. https://docs.aws.amazon.com/autoscaling/application/APIReference/API_PutScheduledAction.html
  ecs_scale_up_cron                      = "cron(0 11 ? * MON-FRI *)"                                                         # M-F at 6AM Eastern. https://docs.aws.amazon.com/autoscaling/application/APIReference/API_PutScheduledAction.html
  ecs_max_size                           = 3                                                                                  # Maximum instances of the application
  ecs_min_size                           = 1                                                                                  # Minimum instances of the application
  ecs_memory_utilization_target_value    = 85                                                                                 # Target memory usage for application
  ecs_cpu_utilization_target_value       = 80                                                                                 # Target CPU value for application
  ecs_scale_in_cooldown                  = 60                                                                                 # Amount of time, in seconds, after an ECS scale in activity completes before another scale in activity can start.
  ecs_scale_out_cooldown                 = 60                                                                                 # Amount of time, in seconds, after an ECS scale out activity completes before another scale out activity can start.
  datadog_image_url                      = "public.ecr.aws/datadog/agent:latest"                                              # Datadog agent docker image URL
  datadog_api_token                      = data.aws_secretsmanager_secret_version.payment-service-datadog.secret_string # Datadog api token stored as a secret
  jfrog_secret_name                      = "Registry-Security"  # Jfrog Auth, managed by DevOps
  splunk_secret_name                     = "service-splunk-token"

  vpc_name = {
    test    = "VPC-CORP-TEST"
    stage   = "CORP-PAYMENTS-DEMO-VPC"
    stagedr = ""
    prod    = "CORP-Prod-VPC"
    proddr  = ""
  }

  region = {
    test    = "us-east-1"
    stage   = "us-east-1"
    stagedr = "us-west-2"
    prod    = "us-east-1"
    proddr  = "us-west-2"
  }

  ecr_repository_host = {
    test    = "111111111111.dkr.ecr.us-east-1.amazonaws.com"
    stage   = "555555555555.dkr.ecr.us-east-1.amazonaws.com"
    stagedr = ""
    prod    = "666666666666.dkr.ecr.us-east-1.amazonaws.com"
    proddr  = ""
  }

  auto_shutdown_enabled = {
    test    = true
    stage   = true
    stagedr = true
    prod    = false
    proddr  = false
  }
}

# Composed variables
locals {
  image_url = "${local.ecr_repository_host[terraform.workspace]}/${local.ecr_repository_name}/${local.app_name}:${var.variable_map["buildNumber"]}"

  log_router_image_url = "${local.ecr_repository_host[terraform.workspace]}/${local.ecr_repository_name}/payment-service.log-router:660375"
}
