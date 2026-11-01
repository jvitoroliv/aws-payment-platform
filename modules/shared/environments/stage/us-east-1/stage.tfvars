aws_region  = "us-east-1"
domain      = "internal-platform.example.com"
environment = "stage"
splunk_dest = "https://http-inputs-example-tenant.splunkcloud.com:443/services/collector/event"

security_groups = {
  tag-stage-mongodb-private-endpoint = {
    description = "TAG Stage MongoDB Private Endpoint Security Group"
    ingress_rules = [
      {
        from_port   = 1024
        to_port     = 65535
        protocol    = "tcp"
        description = "Aiven Stage VPC UE1"
        cidr_ipv4   = "10.96.19.0/24"
      },
      {
        from_port   = 1024
        to_port     = 65535
        protocol    = "tcp"
        description = "Aiven Stage VPC UW2"
        cidr_ipv4   = "10.105.19.0/24"
      }
    ]
  }
}
