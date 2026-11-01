# Upload PowerShell scripts to S3

# Script to configure LCM (Windows Local Configuration Manager)
# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_object" "lcm_config_script" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/LCM-Config.ps1"
  source = "${path.module}/scripts/LCM-Config.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/LCM-Config.ps1" ) ) }"
}

# Script to install PowerShell DSC modules:
# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_object" "install_dsc_modules_script" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/install-dsc-modules.ps1"
  source = "${path.module}/scripts/install-dsc-modules.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/install-dsc-modules.ps1" ) ) }"
}

# Script to install PowerShell DSC modules:
resource "aws_s3_bucket_object" "install_windows_features_script" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/install-windows-features.ps1"
  source = "${path.module}/scripts/install-windows-features.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/install-windows-features.ps1" ) ) }"
}

# Node #1: Main PowerShell configuration script
# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_object" "primary_node_config" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/PrimaryNodeConfig.ps1"
  source = "${path.module}/scripts/PrimaryNodeConfig.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/PrimaryNodeConfig.ps1" ) ) }"
}


# Node #2: Main PowerShell configuration script
resource "aws_s3_bucket_object" "secondary_node_config" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/SecondaryNodeConfig.ps1"
  source = "${path.module}/scripts/SecondaryNodeConfig.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/SecondaryNodeConfig.ps1" ) ) }"
}

# Script to download SQL EE to nodes
data "template_file" "download_sqlee" {
  template = "${ file( "${path.module}/scripts/download-sqlee.ps1.template" ) }"
  vars {
    sql_server_iso_bucket = "${var.sql_server_iso_bucket}"
  }
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_object" "download_sqlee" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/download-sqlee.ps1"
  content = "${data.template_file.download_sqlee.rendered}"
  etag   = "${ md5( file( "${path.module}/scripts/download-sqlee.ps1.template" ) ) }"
}

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket_object" "install_sqlee" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/install-sqlee.ps1"
  source = "${path.module}/scripts/install-sqlee.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/install-sqlee.ps1" ) ) }"
}

resource "aws_s3_bucket_object" "install_sqlee_secondary_node" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/install-sqlee-secondary-node.ps1"
  source = "${path.module}/scripts/install-sqlee-secondary-node.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/install-sqlee-secondary-node.ps1" ) ) }"
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_object" "restore_db_backups" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/restore-db-backups.ps1"
  source = "${path.module}/scripts/restore-db-backups.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/restore-db-backups.ps1" ) ) }"
}

resource "aws_s3_bucket_object" "install_kpk" {
  bucket = "${var.automation_scripts_bucket}"
  key    = "scripts/install-kpk.ps1"
  source = "${path.module}/scripts/install-kpk.ps1"
  etag   = "${ md5( file( "${path.module}/scripts/install-kpk.ps1" ) ) }"
}
