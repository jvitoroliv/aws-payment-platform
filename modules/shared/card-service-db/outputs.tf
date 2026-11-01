# outputs.tf
# Part of the output value definitions module.

output "cluster_members" {
  value = aws_rds_global_cluster.this.global_cluster_members
}

output "connection_details" {
  value = {
    primary = {
      endpoint        = module.aurora_primary.cluster_endpoint
      port            = module.aurora_primary.cluster_port
      reader_endpoint = module.aurora_primary.cluster_reader_endpoint
      region          = "us-east-1"
      resource_id     = module.aurora_primary.cluster_resource_id
      writer_cluster  = local.primary_is_writer_cluster ? true : false
    }
    secondary = {
      endpoint        = module.aurora_secondary.cluster_endpoint
      port            = module.aurora_secondary.cluster_port
      reader_endpoint = module.aurora_secondary.cluster_reader_endpoint
      region          = "us-west-2"
      resource_id     = module.aurora_secondary.cluster_resource_id
      writer_cluster  = local.primary_is_writer_cluster ? false : true
    }
  }
}

output "users" {
  value = {
    for name, user in var.postgres_users : name => {
      auth_token_generation_command = user.iam_auth ? "aws rds generate-db-auth-token --hostname ${local.writer_cluster.endpoint} --port ${local.writer_cluster.port} --username ${name}" : null
      iam_auth                      = user.iam_auth
      password_secret_arn           = user.iam_auth ? null : data.aws_secretsmanager_secret_version.user_password[name].arn
      password_secret_name          = user.iam_auth ? null : user.password_secret_name
      roles                         = user.roles
    }
  }
}

output "writer_cluster" {
  value = local.writer_cluster
}
