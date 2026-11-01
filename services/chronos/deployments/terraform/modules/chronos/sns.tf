# sns.tf
# Manages SNS topics and subscriptions resources.

# Module sourced from internal registry — pin version to prevent unexpected changes
module "chronos_billable_entity_cycling_sns_topic" {
  source = "../infra-modules/sns"

  topic_name = "${local.sns_topic_prefix}billable-entity-cycling"

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

module "chronos_billable_entity_late_fee_sns_topic" {
  source = "../infra-modules/sns"

  topic_name = "${local.sns_topic_prefix}billable-entity-late-fee"

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

module "chronos_billable_entity_delinquency_changed_sns_topic" {
  source = "../infra-modules/sns"

  topic_name = "${local.sns_topic_prefix}billable-entity-delinquency-changed"

  tags = {
    ChronosDeployment = local.chronos_deployment
  }
}

resource "aws_iam_policy" "sns_access" {
  name = "chronos-${var.environment}-${var.aws_region}-sns-perms"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:ListTopics",
        "sns:Publish"
      ],
      "Resource": "arn:aws:sns:${var.aws_region}:${var.aws_account_number}:${local.sns_topic_prefix}*"
    }, {
      "Effect": "Allow",
      "Action": [
        "sns:ListTopics"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
