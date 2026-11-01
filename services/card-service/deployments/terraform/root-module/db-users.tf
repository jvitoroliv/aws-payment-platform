# db-users.tf
# Manages db-users Terraform configuration resources.


resource "postgresql_role" "users" {
  for_each = var.postgres_users

  assume_role        = each.value.assume_role
  connection_limit   = each.value.connection_limit
  create_database    = each.value.create_database
  create_role        = each.value.create_role
  encrypted_password = each.value.iam_auth ? null : each.value.encrypted_password
  inherit            = each.value.inherit
  login              = true
  name               = each.key
  password           = each.value.iam_auth ? null : data.aws_secretsmanager_secret_version.postgres_user_password[each.key].secret_string
  search_path        = each.value.search_path
  statement_timeout  = each.value.statement_timeout
  valid_until        = each.value.valid_until

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [
      roles,
    ]
  }
}

resource "postgresql_grant_role" "user_grant_roles" {
  for_each = merge(
    merge([
      for user_name, user in var.postgres_users : {
        for grant_role_name, grant_role in user.roles : "${user_name}-${grant_role_name}" => {
          user              = user_name
          role              = grant_role_name
          with_admin_option = grant_role.with_admin_option
        }
      }
    ]...),
    # Add the rds_iam role for IAM auth users
    merge([
      for user_name, user in var.postgres_users : {
        "${user_name}-rds_iam" = {
          user              = user_name
          role              = "rds_iam"
          with_admin_option = false
        }
      }
      if user.iam_auth
    ]...)
  )

  role              = each.value.user
  grant_role        = each.value.role
  with_admin_option = each.value.with_admin_option

  depends_on = [postgresql_role.users]
}

resource "aws_iam_role_policy" "iam_auth_role_policies" {
  for_each = merge(
    [
      for postgres_user, user in var.postgres_users : {
        for iam_role in user.iam_roles : "${iam_role}-${postgres_user}" => {
          postgres_user = postgres_user
          iam_role      = iam_role
        }
      }
      if user.iam_auth && length(user.iam_roles) > 0
    ]...
  )

  name_prefix = "card-service-db-${each.value.postgres_user}-"
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
          "arn:aws:rds-db:${data.terraform_remote_state.card_service_db.outputs.connection_details.primary.region}:${data.aws_caller_identity.current.account_id}:dbuser:${data.terraform_remote_state.card_service_db.outputs.connection_details.primary.resource_id}/${each.value.postgres_user}",
          "arn:aws:rds-db:${data.terraform_remote_state.card_service_db.outputs.connection_details.secondary.region}:${data.aws_caller_identity.current.account_id}:dbuser:${data.terraform_remote_state.card_service_db.outputs.connection_details.secondary.resource_id}/${each.value.postgres_user}"
        ]
      },
    ]
  })
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy" "service_role_policies" {
  for_each = merge(
    [
      for postgres_user, user in var.postgres_users : {
        for service in user.services : "${service}-${postgres_user}" => {
          iam_role      = module.ecs_application.ecs.services["${var.environment}-${service}"].tasks_iam_role_name
          postgres_user = postgres_user
        }
      }
      if user.iam_auth && length(user.services) > 0
    ]...
  )

  name_prefix = "card-service-db-${each.value.postgres_user}-"
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
          "arn:aws:rds-db:${data.terraform_remote_state.card_service_db.outputs.connection_details.primary.region}:${data.aws_caller_identity.current.account_id}:dbuser:${data.terraform_remote_state.card_service_db.outputs.connection_details.primary.resource_id}/${each.value.postgres_user}",
          "arn:aws:rds-db:${data.terraform_remote_state.card_service_db.outputs.connection_details.secondary.region}:${data.aws_caller_identity.current.account_id}:dbuser:${data.terraform_remote_state.card_service_db.outputs.connection_details.secondary.resource_id}/${each.value.postgres_user}"
        ]
      },
    ]
  })
}
