aws_account_name                  = "tag-dev"
backup_retention_period           = 7
backup_frequency                  = "daily"
db_cluster_parameter_group_family = "aurora-postgresql16"
engine_version                    = "16.8"
environment                       = "test"
instance_class                    = "db.r5.large"
name                              = "test-card-service-aurora"
postgres_grants                   = {}
postgres_roles                    = {}

parameter_group_parameters = [
  {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pg_cron"
    apply_method = "pending-reboot"
  },
  {
    name         = "cron.database_name"
    value        = "cards"
    apply_method = "pending-reboot"
  }
]

primary = {
  instances = {
    one = {
      apply_immediately = false
      promotion_tier    = 0
    }
  }
  subnets = [
    "subnet-0example000000001",
    "subnet-0example000000002",
    "subnet-0example000000003"
  ]
  vpc_id = "vpc-0example000000001"
}

secondary = {
  instances = {
    one = {
      apply_immediately = false
      promotion_tier    = 0
    }
  }
  subnets = [
    "subnet-0example000000004",
    "subnet-0example000000005",
    "subnet-0example000000006"
  ]
  vpc_id = "vpc-0example000000001"
}

postgres_database_owner_roles = {
  "cards-database-owner" = {
    create_database = false
    create_role     = true
    inherit         = true
  }
}

postgres_databases = {
  "cards" = {
    owner = "cards-database-owner"
  }
}

postgres_extensions = {
  pg_cron = {
    database = "cards"
  }
}

postgres_users = {
  # Terraform currently doesn't work for IAM auth when running app deployments. Remove when the role below is working.
  "github-actions-runner" = {
    create_role          = true
    password_secret_name = "test-github-actions-runner-aurora-password"
    roles = {
      cards-database-owner = {
        with_admin_option = true
      },
      rds_superuser = {},
    }
  }
  "github-actions-runner-iam" = {
    create_role = true
    iam_auth    = true
    roles = {
      cards-database-owner = {
        with_admin_option = true
      },
      rds_superuser = {},
    }
  }
}

security_group_rules = {
  # Currently Security Groups in another VPC cannot be referenced via Transit Gateway
  # Currently there is a failure to create the Rule to allow GH runner in UE1 to access the secondary cluster
  # This feature should be released in the future according to: https://repost.aws/questions/QUYHzCAeoFQ3CofUBWcKfUFA/transit-gw-using-vpc-security-groups
  #
  # Github Runner
  # ingress_from_github_runner_ue1 = {
  #   cluster                  = "all"
  #   description              = "Allow ingress traffic from the Github Runner in us-east-1 to all clusters port 5432"
  #   from_port                = 5432
  #   protocol                 = "tcp"
  #   source_security_group_id = "sg-0example22222222" # tag-test-us-east-1-gh-runner
  #   to_port                  = 5432
  # }

  # The Support Box Security Group ID changes every time it is recreated. Need to make it static or have the Support Box Terraform create the POstgres access SG Rule itself.
  #
  # Support Box
  # ingress_from_support_box = {
  #   cluster                  = "all"
  #   description              = "Allow ingress traffic to all clusters, port 5432 from the Support Box"
  #   from_port                = 5432
  #   protocol                 = "tcp"
  #   source_security_group_id = ""
  #   to_port                  = 5432
  # }

  # Due to the Rules above currently not working, we will need to allow entire VPC CIDR blocks for now
  #
  # VPC Access
  ingress_primary_vpc_to_all = {
    cidr_blocks = ["10.99.196.0/22"]
    cluster     = "all"
    description = "Allow primary VPC ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  ingress_secondary_vpc_to_all = {
    cidr_blocks = ["10.99.204.0/22"]
    cluster     = "all"
    description = "Allow secondary VPC ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }

  # VPN Access
  ingress_madurai_gvpn_to_all = {
    cidr_blocks = [
      "10.29.12.0/23"
    ]
    cluster     = "all"
    description = "Allow Madurai, India GVPN ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  ingress_manchester_gvpn_to_all = {
    cidr_blocks = ["10.0.176.0/21"]
    cluster     = "all"
    description = "Allow Manchester, UK GVPN ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  ingress_melbourne_gvpn_to_all = {
    cidr_blocks = [
      "10.29.76.0/22",
      "10.29.80.0/22"
    ]
    cluster     = "all"
    description = "Allow Melbourne, AU GVPN ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  ingress_office_a_vpn_to_all = {
    cidr_blocks = [
      "10.80.184.0/22",
      "10.80.200.0/22",
      "10.80.204.0/22",
      "10.80.208.0/22"
    ]
    cluster     = "all"
    description = "Allow Office-A GVPN ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  ingress_salvador_gvpn_to_all = {
    cidr_blocks = [
      "10.202.72.0/22",
      "10.202.76.0/22"
    ]
    cluster     = "all"
    description = "Allow São Paulo, BR GVPN ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  ingress_office_b_vpn_to_all = {
    cidr_blocks = ["10.78.0.0/19"]
    cluster     = "all"
    description = "Allow Office-B GVPN ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  ingress_vienna_gvpn_to_all = {
    cidr_blocks = [
      "10.128.178.0/23",
      "10.128.160.0/20"
    ]
    cluster     = "all"
    description = "Allow Vienna, AU GVPN ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
  ingress_west_fargo_gvpn_to_all = {
    cidr_blocks = [
      "10.130.160.0/22",
      "10.130.164.0/22"
    ]
    cluster     = "all"
    description = "Allow West Fargo, ND GVPN ingress traffic to all clusters port 5432"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }
}
