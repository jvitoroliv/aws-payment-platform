aiven_schema_registry_port = 13443
aws_account_number         = "111111111111"
aws_private_subnets        = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
aws_public_subnets         = ["subnet-0example000000004", "subnet-0example000000005", "subnet-0example000000006"]
aws_region                 = "us-east-1"
aws_vpc_id                 = "vpc-0example000000001"
base_url                   = "test.platform.example.com"
core_services_cidr         = "10.94.0.0/22"
dc2_network = [
  "198.51.100.10/32", "198.51.100.11/32", "198.51.100.12/32", "10.200.1.0/24", "198.51.100.13/32"
]
dd_tag_cardinality                         = "orchestrator"
dns_zone_id                                = "Z0EXAMPLE000000"
email_domain                               = "test.platform.example.com"
environment                                = "test"
ingress_allowlists_api_alb                 = ["test-tag-api-public-alb-ingress"]
ingress_allowlists_api_internal_alb        = ["test-tag-api-internal-alb-ingress"]
ingress_allowlists_web_alb                 = ["test-tag-web-public-alb-ingress"]
ingress_allowlists_web_internal_alb        = ["test-tag-web-internal-alb-ingress"]
ingress_allowlists_common_api_alb          = ["test-tag-common-api-public-alb-ingress"]
ingress_allowlists_common_api_internal_alb = ["test-tag-common-api-internal-alb-ingress"]
internal_sftp_publickeys = [
  {
    name      = "tag-sftp-verify"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  },
  {
    name      = "visatest"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  },
  {
    name      = "visatest"
    publickey = "ssh-rsa AAAAB3...REPLACE_WITH_YOUR_PUBLIC_KEY...== deployer@example.com"
  }
]
internal_sftp_users = [
  {
    name    = "tag-sftp-verify",
    homedir = "tag-sftp-verify"
  },
  {
    name    = "visatest",
    homedir = "visatest"
  }
]
internal_ssl_cert_arn = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # Combined cert: *.internal.test.platform.example.com and *.platform.example.com
public_ssl_cert_arn   = "arn:aws:acm:us-east-1:999999999999:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" # Combined cert: *.test.platform.example.com and *.platform.example.com
sftp_vpc_endpoint_id  = "vpce-0cd36a6a9e51bbf25"
sftp_endpoint_cidrs   = ["10.232.198.1/32", "10.232.198.2/32", "10.232.198.3/32"]

finserv_job_count = 2
