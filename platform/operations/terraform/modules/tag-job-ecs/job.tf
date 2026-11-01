variable "all_job_names" {
  type = map(object({}))
  # the optional syntax can be used in future in case we want to modify a specific characteristic like cpu or memory value for an individual job.
  # in following example a default value of 2048 is defied for the cpu which can be overwritten for any job by passing the addtional parameter cpu.
  #  type = map(object({
  #    #cpu=optional(number,2048),container_def=optional(string,"data.template_file.job-visa.rendered")
  #
  #  })


  default = {
    "job-scheduled-event" = {},
    "job-finserv"             = {},
    "job-file-arrival"    = {},
    "job-card-processor"        = {},
    "job-partner"             = {},
    "job-coreplatform"       = {},
    "job-partner_a-coreplatform"  = {},
    "job-partner_a-fi"         = {},
    "job-partner-fi"          = {},
    "job-mail"            = {},
    "job-mastercard"      = {},
    "job-statements"      = {},
    "job-visa"            = {},
    "job-card-migration"  = {}
  }
}

locals {
  container_template = {
    job-scheduled-event = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-scheduled-event"
        job_image              = var.job_scheduled_event_image
        aws_logs_group         = aws_cloudwatch_log_group.job-scheduled-event.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-scheduled-event"].name

        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-corp = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name                   = "job-finserv"
        job_image                  = var.job_finserv_image
        aws_logs_group             = aws_cloudwatch_log_group.job-finserv.name
        datadog_logs_group         = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group     = aws_cloudwatch_log_group.crowdstrikelogs["job-finserv"].name
        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}"
        )
      }
    ),

    job-file-arrival = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-file-arrival"
        job_image              = var.job_file_arrival_image
        aws_logs_group         = aws_cloudwatch_log_group.job-file-arrival.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-file-arrival"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-card-processor = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-card-processor"
        job_image              = var.job_card-processor_image
        aws_logs_group         = aws_cloudwatch_log_group.job-card-processor.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-card-processor"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-partner = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-partner"
        job_image              = var.job_partner_image
        aws_logs_group         = aws_cloudwatch_log_group.job-partner.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-partner"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}"
        )
      }
    ),

    job-coreplatform = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-coreplatform"
        job_image              = var.job_coreplatform_image
        aws_logs_group         = aws_cloudwatch_log_group.job-coreplatform.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-coreplatform"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-partner_a-coreplatform = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-partner_a-coreplatform"
        job_image              = var.job_partner_a_coreplatform_image
        aws_logs_group         = aws_cloudwatch_log_group.job-partner_a-coreplatform.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-partner_a-coreplatform"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-partner_a-fi = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-partner_a-fi"
        job_image              = var.job_partner_a_fi_image
        aws_logs_group         = aws_cloudwatch_log_group.job-partner_a-fi.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-partner_a-fi"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-partner-fi = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-partner-fi"
        job_image              = var.job_partner_fi_image
        aws_logs_group         = aws_cloudwatch_log_group.job-partner-fi.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-partner-fi"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-mail = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-mail"
        job_image              = var.job_mail_image
        aws_logs_group         = aws_cloudwatch_log_group.job-mail.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-mail"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-mastercard = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-mastercard"
        job_image              = var.job_mastercard_image
        aws_logs_group         = aws_cloudwatch_log_group.job-mastercard.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-mastercard"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-statements = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-statements"
        job_image              = var.job_statements_image
        aws_logs_group         = aws_cloudwatch_log_group.job-statements.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-statements"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-visa = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-visa"
        job_image              = var.job_visa_image
        aws_logs_group         = aws_cloudwatch_log_group.job-visa.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-visa"].name


        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    ),

    job-card-migration = templatefile(
      "${path.module}/task-defs/base.json",
      {
        job_name               = "job-card-migration"
        job_image              = var.job_card_migration_image
        aws_logs_group         = aws_cloudwatch_log_group.job-card-migration.name
        datadog_logs_group     = aws_cloudwatch_log_group.datadog.name
        crowdstrike_logs_group = aws_cloudwatch_log_group.crowdstrikelogs["job-card-migration"].name

        region                     = var.aws_region
        environment                = var.environment
        crowdstrike_sensor_version = var.crowdstrike_sensor_version
        datadog_image              = var.datadog_image
        tag_cardinality            = var.dd_tag_cardinality
        dd_api_key                 = var.dd_api_key
        mock_version              = var.mock_version
        crowdstrike-cid            = var.crowdstrike-cid
        artifactory_secret_arn     = var.artifactory_secret_arn
        flags = format("-environment %s -region %s %s",
          var.environment,
          var.aws_region,
          var.chronos_url == "" ? "" : "-chronos-url ${var.chronos_url}",
        )
      }
    )
  }
}


resource "aws_ecs_cluster" "job" {
  name = format("job-%s", var.environment)

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "datadog" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/datadog-job"
}

resource "aws_cloudwatch_log_group" "oneshotter" {
  name = "/aws/fargate/oneshotter-${var.environment}/oneshotter"
}

resource "aws_cloudwatch_log_subscription_filter" "oneshotter" {
  count           = var.log_script_filter
  name            = "oneshotter"
  log_group_name  = aws_cloudwatch_log_group.oneshotter.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//once we're in our new subnets, use this instead of aws_security_group.job.id
resource "aws_security_group" "job" {
  name   = format("job-sg-fargate-%s", var.environment)
  vpc_id = var.aws_vpc_id
  ingress {
    from_port   = 1025
    to_port     = 1025
    protocol    = "tcp"
    cidr_blocks = [local.internal_cidr]
  }
  ingress {
    description = "sftp inbound via palo alto"
    from_port   = 2121
    to_port     = 2121
    protocol    = "tcp"
    cidr_blocks = [
      "203.0.113.1/32",
      "203.0.113.2/32",
      "203.0.113.3/32",
    ]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [local.internal_cidr]
  }
  egress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "mongo"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 465
    to_port     = 465
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 2121
    to_port     = 2121
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "sftp mastercard"
    from_port   = 44323
    to_port     = 44323
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "sentential"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow outbound traffic to the Aiven Schema Registry"
    from_port   = var.aiven_schema_registry_port
    to_port     = var.aiven_schema_registry_port
    protocol    = "tcp"
    cidr_blocks = [var.core_services_cidr]
  }
}

//mock-service-job-scheduled-event resources
resource "aws_ecs_service" "job-scheduled-event" {
  count           = var.use_job_scheduled_event == true ? 1 : 0
  name            = format("job-scheduled-event-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-scheduled-event"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}

resource "aws_cloudwatch_log_group" "job-scheduled-event" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-scheduled-event"
}

resource "aws_cloudwatch_log_subscription_filter" "job-scheduled-event" {
  count           = var.log_script_filter
  name            = "job-scheduled-event"
  log_group_name  = aws_cloudwatch_log_group.job-scheduled-event.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-corp resources
resource "aws_ecs_service" "job-finserv" {
  name            = format("job-finserv-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-finserv"].arn
  desired_count   = var.finserv_job_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}

resource "aws_cloudwatch_log_group" "job-finserv" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-finserv"
}

resource "aws_cloudwatch_log_subscription_filter" "job-finserv" {
  count           = var.log_script_filter
  name            = "job-finserv"
  log_group_name  = aws_cloudwatch_log_group.job-finserv.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-file-arrival resources
# Spread placement across AZs ensures fault tolerance.
resource "aws_ecs_service" "job-file-arrival" {
  name            = format("job-file-arrival-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-file-arrival"].arn
  desired_count   = var.job_file_arrival_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-file-arrival" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-file-arrival"
}

resource "aws_cloudwatch_log_subscription_filter" "job-file-arrival" {
  count           = var.log_script_filter
  name            = "job-file-arrival"
  log_group_name  = aws_cloudwatch_log_group.job-file-arrival.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-card-processor resources
resource "aws_ecs_service" "job-card-processor" {
  name            = format("job-card-processor-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-card-processor"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-card-processor" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-card-processor"
}

resource "aws_cloudwatch_log_subscription_filter" "job-card-processor" {
  count           = var.log_script_filter
  name            = "job-card-processor"
  log_group_name  = aws_cloudwatch_log_group.job-card-processor.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-partner resources
resource "aws_ecs_service" "job-partner" {
  name            = format("job-partner-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-partner"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-partner" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-partner"
}

resource "aws_cloudwatch_log_subscription_filter" "job-partner" {
  count           = var.log_script_filter
  name            = "job-partner"
  log_group_name  = aws_cloudwatch_log_group.job-partner.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-coreplatform resources
# Spread placement across AZs ensures fault tolerance.
# desired_count is managed by auto-scaling; Terraform ignores drift.
resource "aws_ecs_service" "job-coreplatform" {
  name            = format("job-coreplatform-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-coreplatform"].arn
  desired_count   = var.job_coreplatform_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-coreplatform" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-coreplatform"
}

resource "aws_cloudwatch_log_subscription_filter" "job-coreplatform" {
  count           = var.log_script_filter
  name            = "job-coreplatform"
  log_group_name  = aws_cloudwatch_log_group.job-coreplatform.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-partner_a-coreplatform resources
# desired_count is managed by auto-scaling; Terraform ignores drift.
resource "aws_ecs_service" "job-partner_a-coreplatform" {
  name            = format("job-partner_a-coreplatform-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-partner_a-coreplatform"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-partner_a-coreplatform" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-partner_a-coreplatform"
}

resource "aws_cloudwatch_log_subscription_filter" "job-partner_a-coreplatform" {
  count           = var.log_script_filter
  name            = "job-partner_a-coreplatform"
  log_group_name  = aws_cloudwatch_log_group.job-partner_a-coreplatform.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-partner_a-fi resources
# desired_count is managed by auto-scaling; Terraform ignores drift.
resource "aws_ecs_service" "job-partner_a-fi" {
  name            = format("job-partner_a-fi-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-partner_a-fi"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}

resource "aws_cloudwatch_log_group" "job-partner_a-fi" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-partner_a-fi"
}

resource "aws_cloudwatch_log_subscription_filter" "job-partner_a-fi" {
  count           = var.log_script_filter
  name            = "job-partner_a-fi"
  log_group_name  = aws_cloudwatch_log_group.job-partner_a-fi.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

// partner-fi
resource "aws_ecs_service" "job-partner-fi" {
  name            = format("job-partner-fi-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-partner-fi"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}

resource "aws_cloudwatch_log_group" "job-partner-fi" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-partner-fi"
}

resource "aws_cloudwatch_log_subscription_filter" "job-partner-fi" {
  count           = var.log_script_filter
  name            = "job-partner-fi"
  log_group_name  = aws_cloudwatch_log_group.job-partner-fi.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-mail resources
resource "aws_ecs_service" "job-mail" {
  name            = format("job-mail-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-mail"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-mail" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-mail"
}

resource "aws_cloudwatch_log_subscription_filter" "job-mail" {
  count           = var.log_script_filter
  name            = "job-mail"
  log_group_name  = aws_cloudwatch_log_group.job-mail.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-mastercard resources *
# Spread placement across AZs ensures fault tolerance.
resource "aws_ecs_service" "job-mastercard" {
  count           = var.use_job_mastercard == true ? 1 : 0
  name            = format("job-mastercard-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-mastercard"].arn
  desired_count   = var.job_mastercard_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-mastercard" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-mastercard"
}

resource "aws_cloudwatch_log_subscription_filter" "job-mastercard" {
  count           = var.log_script_filter
  name            = "job-mastercard"
  log_group_name  = aws_cloudwatch_log_group.job-mastercard.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-statements resources
resource "aws_ecs_service" "job-statements" {
  name            = format("job-statements-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-statements"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-statements" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-statements"
}

resource "aws_cloudwatch_log_subscription_filter" "job-statements" {
  count           = var.log_script_filter
  name            = "job-statements"
  log_group_name  = aws_cloudwatch_log_group.job-statements.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

//mock-service-job-visa resources *
resource "aws_ecs_service" "job-visa" {
  count           = var.use_job_visa == true ? 1 : 0
  name            = format("job-visa-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-visa"].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_group" "job-visa" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-visa"
}

resource "aws_cloudwatch_log_subscription_filter" "job-visa" {
  count           = var.log_script_filter
  name            = "job-visa"
  log_group_name  = aws_cloudwatch_log_group.job-visa.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

#changes for ado-18

resource "aws_cloudwatch_log_group" "crowdstrikelogs" {

  for_each = var.all_job_names
  name     = "/aws/fargate/${aws_ecs_cluster.job.name}/crowdstrike/${each.key}"
}

resource "aws_ecs_task_definition" "tagjobs" {
  for_each = var.all_job_names

  family                = format("${each.key}-%s", var.environment)
  container_definitions = nonsensitive(local.container_template[each.key])
  # nonsensitive() is used so that container def changes are still visible for review in plan output
  execution_role_arn       = aws_iam_role.job_instance_region_role.arn
  task_role_arn            = aws_iam_role.job_instance_region_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.key == "job-finserv" ? 8192 : 4096
  memory                   = each.key == "job-finserv" ? 61440 : 8192
  volume {
    name = "crowdstrike-falcon-volume"

  }
  volume {
    name = "crowdstrike-private-${each.key}"

  }
  volume {
    name = "crowdstrike-private-datadog"

  }


  tags = {
    NOSCHEDULE = "ECS"
  }

}

resource "aws_ecs_service" "job-card-migration" {
  name            = format("job-card-migration-%s", var.environment)
  cluster         = aws_ecs_cluster.job.id
  task_definition = aws_ecs_task_definition.tagjobs["job-card-migration"].arn
  desired_count   = var.job_card_migration_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.job.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [desired_count]
  }
}

resource "aws_cloudwatch_log_group" "job-card-migration" {
  name = "/aws/fargate/${aws_ecs_cluster.job.name}/job-card-migration"
}

resource "aws_cloudwatch_log_subscription_filter" "job-card-migration" {
  count           = var.log_script_filter
  name            = "job-card-migration"
  log_group_name  = aws_cloudwatch_log_group.job-card-migration.name
  filter_pattern  = ""
  destination_arn = var.log_lambda_arn
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "job-card-migration-autoscaling" {
  source = "../ecs-scaling/ecs-sqs-backlog-per-task-scaling"

  service_name = aws_ecs_service.job-card-migration.name
  cluster_name = aws_ecs_cluster.job.name
  queue_name   = "${var.environment}-${var.aws_region}-card-migration"

  target_value = 25000
  max_capacity = 16
  min_capacity = 2
}
