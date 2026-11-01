# discovery.tf
# Manages discovery Terraform configuration resources.

resource "aws_service_discovery_private_dns_namespace" "payments_scheduler_api_private_dns_namespace" {
  name = format("payments-scheduler-api-dns-namespace-%s-%s", var.aws_region, var.environment)
  vpc  = var.aws_vpc_id
}

resource "aws_service_discovery_service" "payments_scheduler_api_discovery_service" {
  name = format("ecs-web-api-%s-%s", var.aws_region, var.environment)
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.payments_scheduler_api_private_dns_namespace.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}