# ssm_documents.tf
# Manages ssm_documents Terraform configuration resources.


data "template_file" "ssm_config_primary_server" {
  template = "${ file( "${path.module}/scripts/ssm_config_primary_server.template" ) }"
  vars {
    instance_id                     = "${aws_instance.primary_server.id}"
    automation_scripts_bucket       = "${var.automation_scripts_bucket}"
    netbios_domain_name             = "${var.netbios_domain_name}"
    domain_dns_name                 = "${var.domain_dns_name}"
    ad_admin_user                   = "${var.ad_username_secrets_arn}"
    ad_password_secrets_arn         = "${var.ad_password_secrets_arn}"

    # The next interpolations remove the private_ip from the list of all private_ips on the ENI(s).
    # This is due to TF issue https://github.com/terraform-providers/terraform-provider-aws/issues/169
    cluster_ip_node1                = "${ element( compact( split( ",", replace( join( ",", aws_network_interface.primary_server_eni.private_ips ), aws_network_interface.primary_server_eni.private_ip, "" ) ) ), 0 ) }"
    sql_ip_node1                    = "${ element( compact( split( ",", replace( join( ",", aws_network_interface.primary_server_eni.private_ips ), aws_network_interface.primary_server_eni.private_ip, "" ) ) ), 1 ) }"
    # Next lines are hard-coded for 2 nodes, since Terraform v0.11 does not have for loops.
    cluster_ip_node2                = "${ element( compact( split( ",", replace( join( ",", aws_network_interface.secondary_server_eni.*.private_ips[0] ), aws_network_interface.secondary_server_eni.*.private_ip[0], "" ) ) ), 0 ) }"
    # cluster_ip_node3                = "${ element( compact( split( ",", replace( join( ",", aws_network_interface.secondary_server_eni.*.private_ips[1] ), aws_network_interface.secondary_server_eni.*.private_ip[1], "" ) ) ), 0 ) }"
    sql_ip_node2                    = "${ element( compact( split( ",", replace( join( ",", aws_network_interface.secondary_server_eni.*.private_ips[0] ), aws_network_interface.secondary_server_eni.*.private_ip[0], "" ) ) ), 1 ) }"
    # sql_ip_node3                    = "${ element( compact( split( ",", replace( join( ",", aws_network_interface.secondary_server_eni.*.private_ips[1] ), aws_network_interface.secondary_server_eni.*.private_ip[1], "" ) ) ), 1 ) }"

    cluster_name                    = "${var.win_cluster_name}"
    sql_svcacct_creds_secrets_arn   = "${var.sql_svcacct_creds_secrets_arn}"
    sql_login_creds_secrets_arn     = "${var.sql_login_creds_secrets_arn}"
    default_pool_ebs_volumes        = "${local.default_pool_volumes}"
    fci_pool_ebs_volumes            = "${local.fci_pool_volumes}"
    coreplatform_pool_ebs_volumes      = "${local.coreplatform_pool_volumes}"
    archive_pool_ebs_volumes        = "${local.archive_pool_volumes}"
    backup_pool_ebs_volumes         = "${local.backup_pool_volumes}"
    enc_fi                          = "${var.enc_fi}"
    environment                     = "${var.environment}"
    sql_instance_name               = "${upper(var.enc_fi)}_${upper(var.netbios_domain_name)}_FCI"
    sql_cluster_network_name        = "${var.sql_cluster_name}"
    failure_alerts_sns_topic        = "${aws_sns_topic.ssm_automation_alerts.arn}"
    sql_backups_bucket              = "${var.sql_server_backups_bucket}"
    coreplatform_artifacts_bucket      = "${var.coreplatform_artifacts_bucket}"
    executionTimeout                = "${var.executionTimeout}"
  }
}

resource "aws_ssm_document" "ssm_config_primary_server" {
  name            = "${var.win_cluster_name}-ssm-primary-server-config"
  document_type   = "Automation"
  document_format = "YAML"
  # permissions - (Optional) Additional Permissions to attach to the document. 
  content         = "${data.template_file.ssm_config_primary_server.rendered}"
}


data "template_file" "ssm_config_secondary_server" {
  count = "${var.num_of_secondary_nodes}"

  template = "${ file( "${path.module}/scripts/ssm_config_secondary_server.template" ) }"
  vars {
    secondary_svr_number            = "${count.index + 1}"
    instance_id                     = "${element(aws_instance.secondary_server.*.id, count.index)}"
    automation_scripts_bucket       = "${var.automation_scripts_bucket}"
    netbios_domain_name             = "${var.netbios_domain_name}"
    domain_dns_name                 = "${var.domain_dns_name}"
    ad_admin_user                   = "${var.ad_username_secrets_arn}"
    ad_password_secrets_arn         = "${var.ad_password_secrets_arn}"
    # wsfc_static_ip                  = "${element(aws_network_interface.secondary_server_eni.*.private_ips[count.index], 1)}"
    wsfc_static_ip                  = "${ element( compact( split( ",", replace( join( ",", aws_network_interface.secondary_server_eni.*.private_ips[count.index] ), aws_network_interface.secondary_server_eni.*.private_ip[count.index], "" ) ) ), 1 ) }"
    cluster_name                    = "${var.win_cluster_name}"
    sql_svcacct_creds_secrets_arn   = "${var.sql_svcacct_creds_secrets_arn}"
    sql_instance_name               = "${upper(var.enc_fi)}_${upper(var.netbios_domain_name)}_FCI"
    sql_cluster_network_name        = "${var.sql_cluster_name}"
    primary_svr_name                = "${replace(var.hostname_format, "xxx", "001")}"
    enc_fi                          = "${var.enc_fi}"
    environment                     = "${var.environment}"
    failure_alerts_sns_topic        = "${aws_sns_topic.ssm_automation_alerts.arn}"
    coreplatform_artifacts_bucket      = "${var.coreplatform_artifacts_bucket}"
    executionTimeout                = "${var.executionTimeout}"
  }
}

resource "aws_ssm_document" "ssm_config_secondary_server" {
  count = "${var.num_of_secondary_nodes}"

  name            = "${var.win_cluster_name}-ssm-secondary-server-config-${count.index + 1}"
  document_type   = "Automation"
  document_format = "YAML"
  # permissions - (Optional) Additional Permissions to attach to the document. 
  content         = "${element(data.template_file.ssm_config_secondary_server.*.rendered, count.index)}"
}

# SNS topic for alerts on SSM Automation failures
resource "aws_sns_topic" "ssm_automation_alerts" {
    name = "coreplatform_ssm_automation_failures"
    display_name = "For alerts of CorePlatform SSM Automation (SQL Cluster) failures."
    tags        = "${var.tags}"
}

resource "aws_sns_topic_policy" "access" {
  arn    = "${aws_sns_topic.ssm_automation_alerts.arn}"
  policy = "${data.aws_iam_policy_document.sns_topic_policy.json}"
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "ssm_automation_alerts_policy"
  statement {
    sid       = "allow_publish_from_this_ssm"
    effect    = "Allow"
    actions   = [
      "SNS:Publish"
    ]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    resources = ["${aws_sns_topic.ssm_automation_alerts.arn}"]
  }
}
