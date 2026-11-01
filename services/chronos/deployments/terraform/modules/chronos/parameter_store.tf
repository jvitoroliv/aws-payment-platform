# parameter_store.tf
# Manages parameter_store Terraform configuration resources.

resource "aws_ssm_parameter" "db-name" {
  name        = "${local.key_prefix}db-name"
  description = "The parameter description"
  type        = "String"
  value       = "chronos"

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

resource "aws_ssm_parameter" "db-password" {
  name  = "${local.key_prefix}db-password"
  type  = "SecureString"
  value = "__NONE__"

  tags = {
    ChronosDeployment = local.chronos_deployment
  }

  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    # Ignored fields are managed by auto-scaling policies or external controllers
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db-user" {
  name  = "${local.key_prefix}db-user"
  type  = "String"
  value = var.mongo_username

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

resource "aws_ssm_parameter" "mongo-uri" {
  name  = "${local.key_prefix}mongo-uri"
  type  = "String"
  value = var.mongo_uri

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

resource "aws_ssm_parameter" "region" {
  name  = "${local.key_prefix}region"
  type  = "String"
  value = var.aws_region

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

resource "aws_iam_policy" "parameter_access" {
  name = "chronos-${var.environment}-${var.aws_region}-parameter-perms"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:GetParameter"
      ],
      "Resource": "*",
      "Condition":{
        "StringLike":{
          "ssm:resourceTag/ChronosDeployment":[
            "${local.chronos_deployment}"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "chronos_cycling_parameter_perms" {
  policy_arn = aws_iam_policy.parameter_access.arn
  role       = module.chronos_billable_entity_cycling_lambda.execution_role_name
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy_attachment" "chronos_aging_event_parameter_perms" {
  policy_arn = aws_iam_policy.parameter_access.arn
  role       = module.chronos_aging_event_lambda.execution_role_name
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role_policy_attachment" "chronos_api_parameter_perms" {
  policy_arn = aws_iam_policy.parameter_access.arn
  role       = module.chronos_api.execution_role_name
}
