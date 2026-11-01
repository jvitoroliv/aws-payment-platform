// We only deploy one IAM role per AWS account. This terraform deploys the IAM 
// role in test (subprod AWS account) and prod (prod AWS account) only.

###Roles###
resource "aws_iam_role" "datadog_aws_integration_role" {
  count = var.aws_region == "us-east-1" && (var.environment != "dev") ? 1 : 0
  name = "DataDogAWSIntegrationRole_${var.environment}"
  description = "IAM role for DataDog to poll AWS metrics with. This role has reduced privileges to only allow what is currently being used. (If you start a new service, you may need to add permissions to pull metrics from that service.) The default DataDog provided role is found in the DataDog documentation under the AWS integration section."
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = data.aws_iam_policy_document.datadog_assume_role.json
}

###Policy Document###
data "aws_iam_policy_document" "datadog_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
        type = "AWS"
        identifiers = ["arn:aws:iam::999999999999:root"]
    }
    condition {
      test = "StringEquals"
      variable = "sts:ExternalId"
      values = [var.external_id]
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration_policy_document" {
 statement {
  effect = "Allow"
  actions = [
    "autoscaling:Describe*",
    "cloudwatch:Describe*",
    "cloudwatch:Get*",
    "cloudwatch:List*",
    "codedeploy:BatchGet*",
    "codedeploy:List*",
    "ec2:Describe*",
    "ecs:Describe*",
    "ecs:List*",
    "elasticache:DescribeCacheClusters",
    "elasticache:DescribeCacheParameterGroups",
    "elasticache:DescribeCacheSecurityGroups",
    "elasticache:DescribeCacheSubnetGroups",
    "elasticache:DescribeReplicationGroups",
    "elasticache:DescribeReservedCacheNodes",
    "elasticache:DescribeSnapshots",
    "elasticache:DescribeUserGroups",
    "elasticache:DescribeUsers",
    "elasticfilesystem:DescribeFileSystems",
    "elasticfilesystem:DescribeTags",
    "elasticloadbalancing:Describe*",
    "elasticloadbalancing:DescribeLoadBalancers",
    "elasticloadbalancing:DescribeTargetGroups",
    "elasticloadbalancing:DescribeTrustStores",
    "health:DescribeAffectedEntities",
    "health:DescribeEventDetails",
    "health:DescribeEvents",
    "lambda:GetPolicy",
    "lambda:ListCodeSigningConfigs",
    "lambda:ListEventSourceMappings",
    "lambda:ListFunctionUrlConfigs",
    "lambda:ListFunctions",
    "logs:DeleteSubscriptionFilter",
    "logs:Describe*",
    "logs:FilterLogEvents",
    "logs:Get*",
    "logs:PutSubscriptionFilter",
    "logs:TestMetricFilter",
    "rds:Describe*",
    "rds:DescribeDBClusterParameterGroups",
    "rds:DescribeDBClusterSnapshots",
    "rds:DescribeDBClusters",
    "rds:DescribeDBInstanceAutomatedBackups",
    "rds:DescribeDBInstances",
    "rds:DescribeDBParameterGroups",
    "rds:DescribeDBSecurityGroups",
    "rds:DescribeDBSnapshots",
    "rds:DescribeDBSubnetGroups",
    "rds:DescribeEventSubscriptions",
    "rds:DescribeExportTasks",
    "rds:DescribeOptionGroups",
    "rds:List*",
    "route53:List*",
    "sns:ListTopics",
    "sns:Publish",
    "sqs:ListQueues",
    "states:ListStateMachines",
    "support:DescribeTrustedAdvisorCheckResult",
    "support:DescribeTrustedAdvisorChecks",
    "support:RefreshTrustedAdvisorCheck",
    "tag:GetResources",
    "tag:GetTagKeys",
    "tag:GetTagValues"
  ]
  resources = ["*"]
 }
}

###Policy###
resource "aws_iam_policy" "datadog_aws_integration_policy" {
  count = var.aws_region == "us-east-1" && (var.environment != "dev") ? 1 : 0
  name = "datadog_aws_integration_policy"
  description = "IAM policy for DataDog to poll AWS metrics with. This policy has reduced privileges to only allow what is currently being used. (If you start a new service, you may need to add permissions to pull metrics from that service.) The default DataDog provided role is found in the DataDog documentation under the AWS integration section."
  policy = data.aws_iam_policy_document.datadog_aws_integration_policy_document.json
}

###Policy Attachment###
resource "aws_iam_role_policy_attachment" "datadog_policy_attach" {
  count = var.aws_region == "us-east-1" && (var.environment != "dev") ? 1 : 0
  role = aws_iam_role.datadog_aws_integration_role[count.index].name
  policy_arn = aws_iam_policy.datadog_aws_integration_policy[count.index].arn
}