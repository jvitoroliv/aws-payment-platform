#####################
### IAM Resources ###
#####################

# IAM Role for ECS task
resource "aws_iam_role" "ecs_task_assume" {
  name                 = "ecs_task_assume-${local.short_app_name}"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PermissionsBoundaryPolicy"

  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# IAM Role policy for ECS task - includes S3 permissions for migration
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy" "ecs_task_assume" {
  name = "ecs_task_assume-${local.short_app_name}"
  role = aws_iam_role.ecs_task_assume.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:ListSecrets",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource" : [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:payment-service/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketEncryption",
          "s3:PutBucketEncryption",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::payment-service-files"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectMetadata",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::payment-service-files/*"
        ]
      }
    ]
  })
}

# IAM Role for ECS service
resource "aws_iam_role" "ecs_role" {
  name                 = "ecs_role-${local.short_app_name}"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PermissionsBoundaryPolicy"
  assume_role_policy   = data.aws_iam_policy_document.ecs_service_role.json
}

# IAM Role policy for ECS service
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy-${local.short_app_name}"
  policy = data.aws_iam_policy_document.ecs_service_policy.json
  role   = aws_iam_role.ecs_role.id
}

############################
### Cloudwatch Resources ###
############################

# Cloudwatch log group
resource "aws_cloudwatch_log_group" "log_group" {
  name = local.long_app_name
}

# Send cloudwatch logs to firehose for consumption by log aggregator
resource "aws_cloudwatch_log_subscription_filter" "subscription" {
  count           = local.send_logs_to_splunk[terraform.workspace] ? "1" : "0"
  name            = aws_cloudwatch_log_group.log_group.name
  role_arn        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Application-Logs-CWLtoKinesisRole"
  log_group_name  = local.long_app_name
  filter_pattern  = ""
  destination_arn = "arn:aws:firehose:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deliverystream/CorpCentralAppLogstoS3Stream"
  distribution    = "Random"
}

######################
### ECS Resources ####
######################

# ECS Task Definition
resource "aws_ecs_task_definition" "task_definition" {
  family                   = local.short_app_name
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_assume.arn
  task_role_arn            = aws_iam_role.ecs_role.arn
  container_definitions = templatefile("task_definition.tftpl",
    {
      app_image_url = local.image_url
      long_app_name = local.long_app_name
      region        = local.region[terraform.workspace]
      env           = terraform.workspace
    }
  )
  volume {
    name = "sharedFiles"
  }
}

# desired_count is managed by auto-scaling; Terraform ignores drift.
resource "aws_ecs_service" "service" {
  name                               = local.long_app_name
  cluster                            = data.aws_ecs_cluster.ecs_fargate_cluster.arn
  launch_type                        = "FARGATE"
  task_definition                    = aws_ecs_task_definition.task_definition.arn
  desired_count                      = local.ecs_desired_count
  deployment_minimum_healthy_percent = local.ecs_deployment_minimum_healthy_percent
  deployment_maximum_percent         = local.ecs_deployment_maximum_percent
  network_configuration {
    security_groups = [data.aws_security_group.PaymentServiceTLS.id]
    subnets         = data.aws_subnets.private.ids
  }

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [desired_count]
  }

  depends_on = [aws_iam_role_policy.ecs_service_role_policy]
}

##############################
### Autoscaling Resources ####
##############################

# Autoscaling target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = local.ecs_max_size
  min_capacity       = local.ecs_min_size
  resource_id        = "service/${local.ecs_cluster_name}/${local.long_app_name}"
  role_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on         = [aws_ecs_service.service]
}

# Start application on schedule
resource "aws_appautoscaling_scheduled_action" "autoscale_time_up" {
  count              = local.auto_shutdown_enabled[terraform.workspace] ? "1" : "0"
  name               = "autoscale-time-up-${local.short_app_name}"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  schedule           = local.ecs_scale_up_cron
  scalable_target_action {
    min_capacity = 1
    max_capacity = 10
  }
  depends_on = [aws_appautoscaling_target.ecs_target]
}

# Stop application on schedule
resource "aws_appautoscaling_scheduled_action" "autoscale_time_down" {
  count              = local.auto_shutdown_enabled[terraform.workspace] ? "1" : "0"
  name               = "autoscale-time-down-${local.short_app_name}"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  schedule           = local.ecs_scale_down_cron
  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
  
 depends_on = [aws_appautoscaling_target.ecs_target]
}

# Autoscale application based on memory utilization
resource "aws_appautoscaling_policy" "ecs_targettracking_memory" {
  name               = "autoscale-memory-${local.short_app_name}"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  policy_type        = "TargetTrackingScaling"
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  
    target_value       = local.ecs_memory_utilization_target_value
    scale_in_cooldown  = local.ecs_scale_in_cooldown
    scale_out_cooldown = local.ecs_scale_out_cooldown
  }
  
 depends_on = [aws_appautoscaling_target.ecs_target]
}

# Autoscale application based on CPU utilization
resource "aws_appautoscaling_policy" "ecs_targettracking_cpu" {
  name               = "autoscale-cpu-${local.short_app_name}"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = local.ecs_cpu_utilization_target_value
    scale_in_cooldown  = local.ecs_scale_in_cooldown
    scale_out_cooldown = local.ecs_scale_out_cooldown
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}
