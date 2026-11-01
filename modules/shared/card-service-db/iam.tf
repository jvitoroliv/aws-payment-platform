# iam.tf
# Manages IAM roles and policies resources.

# IAM follows the principle of least privilege.
# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy" "iam_auth_role_policies" {
  for_each = merge(
    [
      for postgres_user, user in var.postgres_users : {
        for iam_role in user.iam_roles : "${iam_role}-${postgres_user}" => {
          postgres_user = postgres_user
          iam_role      = iam_role
        }
      }
      if user.iam_auth
    ]...
  )

  name_prefix = "${var.name}-${each.value.postgres_user}-"
  role        = each.value.iam_role
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds-db:connect"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:rds-db:us-east-1:${data.aws_caller_identity.current.account_id}:dbuser:${module.aurora_primary.cluster_resource_id}/${each.value.postgres_user}",
          "arn:aws:rds-db:us-west-2:${data.aws_caller_identity.current.account_id}:dbuser:${module.aurora_secondary.cluster_resource_id}/${each.value.postgres_user}"
        ]
      },
    ]
  })
}
