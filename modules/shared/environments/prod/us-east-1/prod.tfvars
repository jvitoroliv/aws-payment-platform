aws_region  = "us-east-1"
domain      = "internal-platform.example.com"
environment = "prod"
splunk_dest = "https://http-inputs-example-tenant.splunkcloud.com:443/services/collector/event"

security_groups = {
  tag-prod-mongodb-private-endpoint = {
    description = "TAG Prod MongoDB Private Endpoint Security Group"
    ingress_rules = [
      {
        from_port   = 1024
        to_port     = 65535
        protocol    = "tcp"
        description = "Aiven Prod VPC UE1"
        cidr_ipv4   = "10.96.20.0/24"
      },
      {
        from_port   = 1024
        to_port     = 65535
        protocol    = "tcp"
        description = "Aiven Prod VPC UW2"
        cidr_ipv4   = "10.105.20.0/24"
      }
    ]
  }
}
