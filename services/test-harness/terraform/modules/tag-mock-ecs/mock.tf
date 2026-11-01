# mock.tf
# Manages mock Terraform configuration resources.

resource "aws_ecs_cluster" "mock" {
  name = format("mock-%s", var.alt_env_name != "" ? var.alt_env_name : var.environment)

  tags = {
    superjailEnv = var.is_superJail
  }
}

# Egress is restricted to VPC CIDR and required external endpoints.
resource "aws_security_group" "mock" {
  name   = format("mock-sg-fargate-%s", var.alt_env_name != "" ? var.alt_env_name : var.environment)
  vpc_id = var.aws_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "mock_th_from_http_lb_rule" {
  security_group_id = aws_security_group.mock.id

  from_port                    = 6660
  to_port                      = 6660
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.mock-lb.lb_http_sg_id
  description                  = "Allow TH HTTP traffic from LB"
}

resource "aws_vpc_security_group_ingress_rule" "mock_th_from_https_lb_rule" {
  security_group_id = aws_security_group.mock.id

  from_port                    = 6660
  to_port                      = 6660
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.mock-lb.lb_https_sg_id
  description                  = "Allow TH HTTPS traffic from LB"
}

resource "aws_vpc_security_group_ingress_rule" "mock_coreplatform_from_http_lb_rule" {
  security_group_id = aws_security_group.mock.id

  from_port                    = 9090
  to_port                      = 9090
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.mock-lb.lb_http_sg_id
  description                  = "Allow CorePlatform HTTP traffic from LB"
}

resource "aws_vpc_security_group_ingress_rule" "mock_coreplatform_from_https_lb_rule" {
  security_group_id = aws_security_group.mock.id

  from_port                    = 9090
  to_port                      = 9090
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.mock-lb.lb_https_sg_id
  description                  = "Allow CorePlatform HTTPS traffic from LB"
}

resource "aws_vpc_security_group_ingress_rule" "mock_chronos_from_http_lb_rule" {
  security_group_id = aws_security_group.mock.id

  from_port                    = 9096
  to_port                      = 9096
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.mock-lb.lb_http_sg_id
  description                  = "Allow Chronos HTTP traffic from LB"
}

resource "aws_vpc_security_group_ingress_rule" "mock_chronos_from_https_lb_rule" {
  security_group_id = aws_security_group.mock.id

  from_port                    = 9096
  to_port                      = 9096
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.mock-lb.lb_https_sg_id
  description                  = "Allow Chronos HTTPS traffic from LB"
}

resource "aws_ecs_service" "mock" {
  name                 = format("mock-%s", var.environment)
  cluster              = aws_ecs_cluster.mock.id
  force_new_deployment = true
  triggers = {
    redeployment = plantimestamp()
  }
  task_definition = aws_ecs_task_definition.mock.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.th.arn
    container_name   = "th"
    container_port   = 6660
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.coreplatform.arn
    container_name   = "coreplatform"
    container_port   = 9090
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.chronos.arn
    container_name   = "chronos"
    container_port   = 9096
  }

  network_configuration {
    security_groups  = [aws_security_group.mock.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "mock" {
  family                   = format("mock-%s", var.environment)
  execution_role_arn       = var.iam_role_arn
  task_role_arn            = var.iam_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096

  container_definitions = templatefile(
    "${path.module}/task-defs/base.json",
    {
      th_name         = "th"
      th_image        = var.th_image
      coreplatform_name  = "coreplatform"
      coreplatform_image = var.coreplatform_image
      chronos_name    = "chronos"
      chronos_image   = var.chronos_image
      cpu             = 512
      memory          = 1024
      region          = var.aws_region
      environment     = var.environment

      th_flags             = format("-environment ${var.environment} -region ${var.aws_region} -staticDir=/web -apiurl ${var.api_url}%s%s", var.chronos_api_url == "" ? "" : " -chronosURL ${var.chronos_api_url}", var.superjail == "" ? "" : " -superjail ${var.superjail}")
      coreplatform_flags      = format("-environment ${var.environment} -region ${var.aws_region} -apiurl ${var.api_url}%s", var.superjail == "" ? "" : " -superjail ${var.superjail}")
      th_logs_group        = aws_cloudwatch_log_group.th.name
      coreplatform_logs_group = aws_cloudwatch_log_group.th.name
      datadog_logs_group   = aws_cloudwatch_log_group.datadog.name
      chronos_logs_group   = aws_cloudwatch_log_group.chronos.name
      datadog_image        = var.datadog_image
      dd_api_key_arn       = var.dd_api_key_arn
      artifactory_arn      = data.aws_secretsmanager_secret.artifactory.arn
    }
  )

  tags = {
    superjailEnv = var.is_superJail
  }
}

resource "aws_cloudwatch_log_group" "th" {
  name = "/aws/fargate/${aws_ecs_cluster.mock.name}/test-harness"
}

resource "aws_cloudwatch_log_group" "coreplatform" {
  name = "/aws/fargate/${aws_ecs_cluster.mock.name}/mock-coreplatform"
}

resource "aws_cloudwatch_log_group" "chronos" {
  name = "/aws/fargate/${aws_ecs_cluster.mock.name}/mock-chronos"
}

resource "aws_cloudwatch_log_group" "datadog" {
  name = "/aws/fargate/${aws_ecs_cluster.mock.name}/datadog-mock"
}

# Shared module — changes here affect all consumers. Semver applies.
# Module sourced from internal registry — pin version to prevent unexpected changes
module "mock-lb" {
  source             = "../tag-alb"
  name               = "mock"
  environment        = var.alt_env_name != "" ? var.alt_env_name : var.environment
  mock_coreplatform_arn = aws_lb_target_group.coreplatform.arn
  mock_chronos_arn   = aws_lb_target_group.chronos.arn
  testharness_arn    = aws_lb_target_group.th.arn
  aws_region         = var.aws_region
  subnet_ids         = var.public_subnet_ids
  web_ssl_cert_arn   = var.web_ssl_cert_arn
  vpc_id             = var.aws_vpc_id
  dns_zone_id        = var.dns_zone_id
  ingress_whitelist  = var.ingress_whitelist
  egress_whitelist   = var.egress_whitelist
  idle_timeout       = var.idle_timeout
  ingress_rules_http = [
    # [from_port, to_port, protocol, description]
    [80, 80, "tcp", "LB can be reached by this"],
  ]
  ingress_rules_https = [
    # [from_port, to_port, protocol, description]
    [443, 443, "tcp", "LB can be reached by this"],
  ]
  egress_rules = [
    # [from_port, to_port, protocol, description]
    [6660, 6660, "tcp", "Forward to TH container port"],
    [9090, 9090, "tcp", "Forward to CorePlatform container port"],
    [9096, 9096, "tcp", "Forward to Chronos container port"],
  ]
}

data "aws_secretsmanager_secret" "artifactory" {
  name = "registry_cloud_credentials"
}
