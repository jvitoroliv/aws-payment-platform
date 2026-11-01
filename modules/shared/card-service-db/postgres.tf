# postgres.tf
# Manages postgres Terraform configuration resources.

resource "postgresql_role" "database_owner_roles" {
  for_each = var.postgres_database_owner_roles

  bypass_row_level_security = each.value.bypass_row_level_security
  create_database           = each.value.create_database
  create_role               = each.value.create_role
  inherit                   = each.value.inherit
  login                     = false # For roles that act as users, create under "logins" variable
  name                      = each.key
  replication               = each.value.replication
  roles                     = each.value.roles
  search_path               = each.value.search_path
  skip_drop_role            = each.value.skip_drop_role
  skip_reassign_owned       = each.value.skip_reassign_owned
  statement_timeout         = each.value.statement_timeout
}

resource "postgresql_database" "databases" {
  for_each = var.postgres_databases

  allow_connections = each.value.allow_connections
  connection_limit  = each.value.connection_limit
  encoding          = each.value.encoding
  is_template       = false # If we want to create templates then we should create another resource "template_databases" or similar that this resource can depend on
  lc_collate        = each.value.lc_collate
  lc_ctype          = each.value.lc_ctype
  name              = each.key
  owner             = each.value.owner
  tablespace_name   = each.value.tablespace_name
  template          = each.value.template

  depends_on = [postgresql_role.database_owner_roles] # Ensure DB owner roles are created before databases so that owner roles can be assigned as DB owners
}

resource "postgresql_role" "roles" {
  for_each = var.postgres_roles

  bypass_row_level_security = each.value.bypass_row_level_security
  create_database           = each.value.create_database
  create_role               = each.value.create_role
  inherit                   = each.value.inherit
  login                     = false # For roles that act as users, create under "logins" variable
  name                      = each.key
  replication               = each.value.replication
  roles                     = each.value.roles
  search_path               = each.value.search_path
  skip_drop_role            = each.value.skip_drop_role
  skip_reassign_owned       = each.value.skip_reassign_owned
  statement_timeout         = each.value.statement_timeout

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [
      roles,
    ]
  }
}

resource "postgresql_grant_role" "role_grant_roles" {
  for_each = merge([
    for role_name, role in var.postgres_roles : {
      for grant_role_name, grant_role in role.roles : "${role_name}-${grant_role_name}" => {
        role              = role_name
        grant_role        = grant_role_name
        with_admin_option = grant_role.with_admin_option
      }
    }
  ]...)

  role              = each.value.role
  grant_role        = each.value.grant_role
  with_admin_option = each.value.with_admin_option

  depends_on = [postgresql_role.roles]
}

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
  password           = each.value.iam_auth ? null : data.aws_secretsmanager_secret_version.user_password[each.key].secret_string
  search_path        = each.value.search_path
  statement_timeout  = each.value.statement_timeout
  valid_until        = each.value.valid_until

  depends_on = [postgresql_role.roles] # Ensure roles are created before users so that users can be assigned roles

  lifecycle {
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

resource "postgresql_grant" "grants" {
  for_each = var.postgres_grants

  columns     = each.value.columns
  database    = each.value.database
  object_type = each.value.object_type
  objects     = each.value.objects
  privileges  = each.value.privileges
  role        = each.value.role
  schema      = each.value.schema
}

resource "postgresql_extension" "extensions" {
  for_each = var.postgres_extensions

  create_cascade = each.value.create_cascade
  database       = each.value.database
  drop_cascade   = each.value.drop_cascade
  name           = each.key
  schema         = each.value.schema
  version        = each.value.version
}
