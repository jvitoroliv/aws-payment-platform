# sftp.tf
# Part of the sftp Terraform configuration module.

resource "aws_instance" "mock_sftp_instance" {
  // AMI: The most recent from CloudOps
  ami                  = data.aws_ami.aws_linux.id
  iam_instance_profile = aws_iam_instance_profile.sftp_instance_region_role.name
  instance_type        = "t3.nano"
  monitoring           = true
  root_block_device {
    delete_on_termination = true
    volume_size           = 200
  }
  subnet_id = var.aws_private_subnets[0]
  tags = {
    Environment      = var.environment
    Name             = "${var.environment}-sftp"
    Role             = "SFTP"
    NOSCHEDULE       = "ENABLE"
    owner            = "user@example-company.com"
    billingid        = "CORP-XXXXX-XXXX-XXXXX"
    approle          = "worker"
    appid            = "Support.${var.environment}"
    cas-patching-utc = "cattle"
  }
  volume_tags = {
    Name        = "${var.environment}-sftpvolume"
    Environment = var.environment
    Role        = "SFTP"
    billingid   = "CORP-XXXXX-XXXX-XXXXX"
    owner       = "user@example-company.com"
    approle     = "worker"
    appid       = "Support.${var.environment}"
  }
  user_data = templatefile(
    "${path.module}/init/startup",
    {}
  )
  vpc_security_group_ids = [
    aws_security_group.mock_sftp_sg.id
  ]
}
