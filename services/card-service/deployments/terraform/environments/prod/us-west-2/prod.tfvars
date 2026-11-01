aiven_kafka_users = [
  "tag_prod_card_service_company_consumer",
  "tag_prod_card_service_producer",
]
aiven_project = "prod"
aws_region    = "us-west-2"
aws_vpc_id    = "vpc-0example000000001"
ingress_allowlists = ["prod-cards-api-internal-alb-ingress"]
card_service_db_datadog_agent = {
  autoscaling_max_capacity = 1
  autoscaling_min_capacity = 1
  task_definition_cpu      = 1024
  task_definition_memory   = 2048
}
card_service_dispatcher = {
  autoscaling_max_capacity = 1
  autoscaling_min_capacity = 1
  task_definition_cpu      = 2048
  task_definition_memory   = 4096
}
card_service_api = {
  autoscaling_max_capacity = 2
  autoscaling_min_capacity = 2
  endpoint_url             = "cards-internal-prod-us-west-2.platform.example.com"
  task_definition_cpu      = 2048
  task_definition_memory   = 4096
}
card_service_company_consumer = {
  autoscaling_max_capacity = 1
  autoscaling_min_capacity = 1
  task_definition_cpu      = 2048
  task_definition_memory   = 4096
}
card_service_producer = {
  autoscaling_max_capacity = 1
  autoscaling_min_capacity = 1
  task_definition_cpu      = 2048
  task_definition_memory   = 4096
}
cidr_vpc_ue1             = "10.99.216.0/22"
cidr_vpc_uw2             = "10.99.220.0/22"
dns_zone_id              = "Z0EXAMPLE000000"
environment              = "prod"
hsm_cidr                 = "10.230.204.100/32"
load_balancer_ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
postgres_users = {
  "card-service-db-datadog-agent-us-west-2" = {
    iam_auth = true
    roles = {
      datadog-role = {},
    }
    services = ["card-service-db-datadog-agent"]
  }
}
web_ssl_cert_arn = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
