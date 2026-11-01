
# Security Group for SQL Server instances
# ---------------------------------------------------------------------

data "aws_subnet" "first_subnet" {
  id = "${element(var.subnet_ids, 0)}"
}

resource "aws_security_group" "sql_server" {
  name        = "coreplatform-${upper(var.enc_fi)}-${var.netbios_domain_name}-sql-server"
  description = "CorePlatform - ${upper(var.enc_fi)} - ${var.netbios_domain_name} - SQL Server nodes"
  vpc_id      = "${data.aws_subnet.first_subnet.vpc_id}"  # Get VPC ID based on any Subnet.
  tags        = "${var.tags}"
  
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow RDP
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  # WSFC Cluster comms
  ingress {
    from_port = 3343
    to_port = 3343
    protocol = "tcp"
    self = true
    description = "Main port for WSFC Cluster communication"
  }
  
  ingress {
    from_port = 3343
    to_port = 3343
    protocol = "udp"
    self = true
    description = "Main port for WSFC Cluster communication"
  }
  
  ingress {
    from_port = 135
    to_port = 135
    protocol = "tcp"
    self = true
    description = "Cluster DCOM Traffic [RPC, EPM]"
  }
  
  ingress {
    from_port = 137
    to_port = 137
    protocol = "udp"
    self = true
    description = "User and Computer Authentication [NetLogon, NetBIOS]"
  }
  
  ingress {
    from_port = 139
    to_port = 139
    protocol = "tcp"
    self = true
    description = "User and Computer Authentication [NetLogon, NetBIOS]"
  }
  
  ingress {
    from_port = 445
    to_port = 445
    protocol = "tcp"
    self = true
    description = "User and Computer Authentication [SMB, SMB2, CIFS] - required by WSFC"
  }
      
  ingress {
    from_port = 49152
    to_port = 65535
    protocol = "tcp"
    self = true
    description = "Dynamic TCP for Cluster."
  }
  
  # allow ping
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    self      = true
    description = "Required for Cluster operations."
  }
  
  # For SQL Server
  ingress {
    from_port = 1433
    to_port = 1433
    protocol = "tcp"
    self = true
    description = "for SQL Server"
  }
  
  ingress {
    from_port = 1434
    to_port = 1434
    protocol = "udp"
    self = true
    description = "for SQL Browser"
  }


  ingress {
    from_port = 1433
    to_port = 1433
    protocol = "tcp"
    security_groups = ["${var.inbound_security_group_ids}"]
    description = "for SQL Server"
  }
  ingress {
    from_port = 1434
    to_port = 1434
    protocol = "udp"
    security_groups = ["${var.inbound_security_group_ids}"]
    description = "for SQL Browser"
  }
  ingress {
    from_port = 49152
    to_port = 65535
    protocol = "tcp"
    security_groups = ["${var.inbound_security_group_ids}"]
    description = "Dynamic port range for SQL instances"
  }

}
