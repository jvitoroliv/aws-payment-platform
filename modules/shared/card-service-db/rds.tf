# rds.tf
# Manages RDS database configuration resources.

resource "random_password" "master" {
  length  = 20
  special = false
}

resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = "${var.name}-global-cluster"
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  storage_encrypted         = true
}

# Module sourced from internal registry — pin version to prevent unexpected changes
module "aurora_primary" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.3.1"

  providers = { aws = aws.primary }

  auto_minor_version_upgrade            = true
  backup_retention_period               = var.backup_retention_period
  create_db_subnet_group                = true
  db_subnet_group_name                  = "${var.name}-primary-cluster"
  database_name                         = "postgres"
  engine                                = aws_rds_global_cluster.this.engine
  engine_version                        = aws_rds_global_cluster.this.engine_version
  global_cluster_identifier             = aws_rds_global_cluster.this.id
  iam_database_authentication_enabled   = true
  instance_class                        = var.instance_class
  instances                             = var.primary.instances
  kms_key_id                            = data.aws_kms_key.primary.arn
  manage_master_user_password           = false
  master_password                       = random_password.master.result
  master_username                       = "root"
  name                                  = "${var.name}-primary-cluster"
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  preferred_maintenance_window          = "mon:04:00-mon:05:00"
  skip_final_snapshot                   = true
  subnets                               = var.primary.subnets
  vpc_id                                = var.primary.vpc_id

  create_db_cluster_parameter_group     = length(var.parameter_group_parameters) > 0
  db_cluster_parameter_group_name       = length(var.parameter_group_parameters) > 0 ? var.name : null
  db_cluster_parameter_group_family     = length(var.parameter_group_parameters) > 0 ? var.db_cluster_parameter_group_family : null
  db_cluster_parameter_group_parameters = var.parameter_group_parameters

  security_group_rules = {
    for key, rule in var.security_group_rules : key => rule
    if rule.cluster == "all" || rule.cluster == "primary"
  }

  cluster_tags = merge(
    {
      "backup"           = "yes"
      "cas-patching-utc" = "first-monday-04"
    },
    var.backup_frequency == "hourly" ? { "backuphourly" = "yes" } : {}
  )

}

module "aurora_secondary" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.3.1"

  providers = { aws = aws.secondary }

  is_primary_cluster = false

  auto_minor_version_upgrade            = true
  backup_retention_period               = var.backup_retention_period
  create_db_subnet_group                = true
  db_subnet_group_name                  = "${var.name}-secondary-cluster"
  engine                                = aws_rds_global_cluster.this.engine
  engine_version                        = aws_rds_global_cluster.this.engine_version
  global_cluster_identifier             = aws_rds_global_cluster.this.id
  iam_database_authentication_enabled   = true
  instance_class                        = var.instance_class
  instances                             = var.secondary.instances
  kms_key_id                            = data.aws_kms_key.secondary.arn
  manage_master_user_password           = false
  master_password                       = random_password.master.result
  master_username                       = "root"
  name                                  = "${var.name}-secondary-cluster"
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  preferred_maintenance_window          = "wed:04:00-wed:05:00"
  skip_final_snapshot                   = true
  source_region                         = data.aws_region.primary.name
  subnets                               = var.secondary.subnets
  vpc_id                                = var.secondary.vpc_id

  create_db_cluster_parameter_group     = length(var.parameter_group_parameters) > 0
  db_cluster_parameter_group_name       = length(var.parameter_group_parameters) > 0 ? var.name : null
  db_cluster_parameter_group_family     = length(var.parameter_group_parameters) > 0 ? var.db_cluster_parameter_group_family : null
  db_cluster_parameter_group_parameters = var.parameter_group_parameters

  security_group_rules = {
    for key, rule in var.security_group_rules : key => rule
    if rule.cluster == "all" || rule.cluster == "secondary"
  }

  cluster_tags = merge(
    {
      "backup"           = "yes"
      "cas-patching-utc" = "first-wednesday-04"
    },
    var.backup_frequency == "hourly" ? { "backuphourly" = "yes" } : {}
  )
}
