# AWS SecretsManager Secret that contains the endpoints of the Aurora cluster
resource "aws_secretsmanager_secret" "cluster_endpoint" {
  #ts:skip=AWS.SecretsManagerSecret.DP.MEDIUM.0036 Ignore non-CMK KMS encryption for now
  name = "${var.name}-endpoint"
}

resource "aws_secretsmanager_secret_version" "cluster_endpoint" {
  secret_id = aws_secretsmanager_secret.cluster_endpoint.id
  secret_string = jsonencode({
    primary_endpoint   = module.aurora_primary.cluster_endpoint
    secondary_endpoint = module.aurora_secondary.cluster_endpoint
  })
}
