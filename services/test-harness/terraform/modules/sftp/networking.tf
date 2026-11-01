# networking.tf
# Part of the networking Terraform configuration module.

resource "aws_security_group" "mock_sftp_sg" {
  name        = "Allow_SFTP"
  description = "Allow SFTP Internal"
  vpc_id      = var.aws_vpc_id
  ingress {
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = 2222
    protocol    = "tcp"
    to_port     = 2222
  }
  ingress {
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_route53_record" "mock_sftp_internal_dns" {
  zone_id = data.terraform_remote_state.shared.outputs.internal_dns_zone_id
  name    = "${var.environment}-${var.aws_region}-sftp.${data.terraform_remote_state.shared.outputs.internal_dns_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mock_sftp_instance.private_ip]
}