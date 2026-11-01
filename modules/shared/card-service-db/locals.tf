# locals.tf
# Manages local value computations resources.

locals {
  tags = {
    app_id      = "APP_XXX"
    approle     = "db"
    billingid   = "CORP-XXXXX-XXXX-XXXXX"
    environment = var.environment
    lob         = "C-PS"
    Name        = "${var.environment}-card-service-aurora"
    owner       = "user@example-company.com"
    project     = "TAG"
    repository  = "shared-terraform"
  }

  writer_cluster_arn = [
    for member in aws_rds_global_cluster.this.global_cluster_members : member.db_cluster_arn
    if member.is_writer
  ][0]

  primary_is_writer_cluster = local.writer_cluster_arn == module.aurora_primary.cluster_arn ? true : false

  writer_cluster = {
    endpoint = local.primary_is_writer_cluster ? module.aurora_primary.cluster_endpoint : module.aurora_secondary.cluster_endpoint
    port     = local.primary_is_writer_cluster ? module.aurora_primary.cluster_port : module.aurora_secondary.cluster_port
    region   = local.primary_is_writer_cluster ? "us-east-1" : "us-west-2"
  }
}
