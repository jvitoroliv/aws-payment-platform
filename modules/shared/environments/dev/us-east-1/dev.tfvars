aws_region  = "us-east-1"
domain      = "internal-platform.example.com"
environment = "dev"
splunk_dest = "https://http-inputs-example-tenant.splunkcloud.com:443/services/collector/event"

security_groups = {
  tag-dev-mongodb-private-endpoint = {
    description = "TAG Dev MongoDB Private Endpoint Security Group"
    ingress_rules = [
      {
        from_port   = 1024
        to_port     = 65535
        protocol    = "tcp"
        description = "Aiven Dev VPC UE1"
        cidr_ipv4   = "10.96.18.0/24"
      },
      {
        from_port   = 1024
        to_port     = 65535
        protocol    = "tcp"
        description = "Aiven Dev VPC UW2"
        cidr_ipv4   = "10.105.18.0/24"
      },
      {
        from_port      = 1024
        to_port        = 65535
        protocol       = "tcp"
        description    = "finserv-internal-global-protect-vpn-ipv4-pl us-east-1"
        prefix_list_id = "pl-0e75f5422571ed3bd"
      }
    ]
  }
}
