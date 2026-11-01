# main.tf
# Part of the primary resource definitions module.


resource "aws_s3_bucket" "ami-image-logs" {
  bucket = "finserv-cpt-${var.tags["Project"]}-ami-image-logs-s3bucket-${var.region}-${var.tags["Environment"]}"
  region        = "${var.region}"
  force_destroy = true
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket" "backup-reports" {
  bucket = "finserv-cpt-${var.tags["Project"]}-backup-reports-s3bucket-${var.region}-${var.tags["Environment"]}"
  region        = "${var.region}"
  force_destroy = true
}

#finserv-cpt-platform-services-backup-reports-s3bucket-us-east-1-dev
#finserv-cpt-platform-services-ami-image-logs-s3bucket-us-east-1-dev
resource "aws_iam_role" "Backup-initiator-role" {
  name               = "${var.stack_prefix}-Backup-initiator-role-${var.unique_name}"
  # Trust policy — defines which principals can assume this role via STS
  assume_role_policy = "${file("${path.module}/files/lambda-role.json")}"
}

resource "aws_iam_role_policy" "Backup-initiator-policy" {
  name = "${var.stack_prefix}-Backup-initiator-role-${var.unique_name}"
  role = "${aws_iam_role.Backup-initiator-role.id}"
  policy = "${file("${path.module}/files/Backup-worker-role.json")}"
}

resource "aws_iam_role" "Backup-worker-role" {
  name               = "${var.stack_prefix}-Backup-worker-role-${var.unique_name}"
  assume_role_policy = "${file("${path.module}/files/lambda-role.json")}"
}

resource "aws_iam_role_policy" "Backup-worker-policy" {
  name = "${var.stack_prefix}-Backup-worker-role-${var.unique_name}"
  role = "${aws_iam_role.Backup-worker-role.id}"
  policy = "${file("${path.module}/files/Backup-worker-role.json")}"
}

resource "aws_iam_role" "Cloudwatch-log-role" {
  name               = "${var.stack_prefix}-Cloudwatch-log-role-${var.unique_name}"
  assume_role_policy = "${file("${path.module}/files/lambda-role.json")}"
}

resource "aws_iam_role_policy" "Cloudwatch-log-policy" {
  name = "${var.stack_prefix}-Cloudwatch-log-role-${var.unique_name}"
  role = "${aws_iam_role.Cloudwatch-log-role.id}"
  policy = "${file("${path.module}/files/Cloudwatch-log-role.json")}"
}

# This role is scoped to the specific actions the service needs.
resource "aws_iam_role" "Report-mailer-role" {
  name               = "${var.stack_prefix}-Report-mailer-role-${var.unique_name}"
  assume_role_policy = "${file("${path.module}/files/lambda-role.json")}"
}

# IAM follows the principle of least privilege.
resource "aws_iam_role_policy" "Report-mailer-policy" {
  name = "${var.stack_prefix}-Report-mailer-role-${var.unique_name}"
  role = "${aws_iam_role.Report-mailer-role.id}"
  policy = "${file("${path.module}/files/Report-mailer-role.json")}"
}

data "archive_file" "backup_initiator" {
  type        = "zip"
  source_file = "${path.module}/lambda/backup_initiator_lambda.py"
  output_path = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}_backup_initiator_lambda.zip"
}

resource "aws_lambda_function" "backup_initiator_lambda" {
          filename          = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}_backup_initiator_lambda.zip"
          function_name    = "schedule_backup_initiator_backups"
	  description      = "Automatically backup..."
	  role             = "${aws_iam_role.Backup-initiator-role.arn}"
	  timeout          = 300
	  handler          = "backup_initiator_lambda.lambda_handler"
	  runtime          = "python2.7"
	  source_code_hash = "${data.archive_file.backup_initiator.output_base64sha256}"
          publish           = true
          environment = {
		    variables = {
			      #region                = "${var.region}"
			      #ami_owner             = "${var.ami_owner}"
			      block_device_mappings = "${jsonencode(var.block_device_mappings)}"
	    }
	  }
	}
	
	
data "archive_file" "ami_backup_worker" {
  type        = "zip"
  source_file = "${path.module}/lambda/ami_backup_worker_lambda.py"
  output_path = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}_ami_backup_worker_lambda.zip"
}

resource "aws_lambda_function" "ami_backup_worker_lambda" {
          filename          = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}_ami_backup_worker_lambda.zip"
          function_name    = "schedule_ami_backup_worker_backups"
	  description      = "Automatically backup EC2 instance (create AMI)"
	  role             = "${aws_iam_role.Backup-worker-role.arn}"
	  timeout          = 300
	  handler          = "ami_backup_worker_lambda.lambda_handler"
	  runtime          = "python2.7"
	  source_code_hash = "${data.archive_file.ami_backup_worker.output_base64sha256}"
          publish           = true
          environment = {
		    variables = {
			      #region                = "${var.region}"
			      #ami_owner             = "${var.ami_owner}"
			      block_device_mappings = "${jsonencode(var.block_device_mappings)}"
	    }
	  }
	}

data "archive_file" "backup_report_mailer" {
  type        = "zip"
  source_file = "${path.module}/lambda/backup_report_mailer_lambda.py"
  output_path = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}_backup_report_mailer_lambda.zip"
}

resource "aws_lambda_function" "backup_report_mailer_lambda" {
          filename          = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}_backup_report_mailer_lambda.zip"
          function_name    = "schedule_backup_report_mailer"
	  description      = "email reports"
	  role             = "${aws_iam_role.Report-mailer-role.arn}"
	  timeout          = 300
	  handler          = "backup_report_mailer_lambda.lambda_handler"
	  runtime          = "python2.7"
	  source_code_hash = "${data.archive_file.backup_report_mailer.output_base64sha256}"
          publish           = true
       #   environment = {
		   # variables = {
			      #region                = "${var.region}"
			      #ami_owner             = "${var.ami_owner}"
			      #block_device_mappings = "${jsonencode(var.block_device_mappings)}"
	    #}
	  #}
	}

  data "archive_file" "backup_store_logs" {
  type        = "zip"
  source_file = "${path.module}/lambda/backup_store_logs_lambda.py"
  output_path = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}_backup_store_logs_lambda.zip"
}

resource "aws_lambda_function" "backup_store_logs_lambda" {
          filename          = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}_backup_store_logs_lambda.zip"
          function_name    = "schedule_backup_store_logs"
	  description      = "email reports"
	  role             = "${aws_iam_role.Report-mailer-role.arn}"
	  timeout          = 300
	  handler          = "backup_store_logs_lambda.lambda_handler"
	  runtime          = "python2.7"
	  source_code_hash = "${data.archive_file.backup_store_logs.output_base64sha256}"
          publish           = true
          environment = {
		    variables = {
			      s3imagelogsbucketName=  "${aws_s3_bucket.ami-image-logs.id}"
            s3backreportsbucketName=  "${aws_s3_bucket.backup-reports.id}"
	    }
	  }
	}



###########
resource "aws_cloudwatch_event_rule" "backup_initiator" {
  ##name                = "${module.label_backup.id}"
  name = "${var.stack_prefix}_ami_bckup_event_${var.unique_name}"
  description         = "Schedule for AMI snapshot backups"
  ##schedule_expression = "${null_resource.schedule.triggers.backup}"
  schedule_expression = "cron(${var.cron_expression})"
}

resource "aws_cloudwatch_event_target" "backup_initiator" {
      rule = "${aws_cloudwatch_event_rule.backup_initiator.name}"
      target_id = "${aws_lambda_function.backup_initiator_lambda.id}"
      arn = "${aws_lambda_function.backup_initiator_lambda.arn}"
}

resource "aws_lambda_permission" "backup_initiator" {
    statement_id = "${var.stack_prefix}_AllowExecutionFromCloudWatch_${var.unique_name}"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.backup_initiator_lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.backup_initiator.arn}"
}
