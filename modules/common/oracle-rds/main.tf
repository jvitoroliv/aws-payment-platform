# main.tf
# Part of the primary resource definitions module.

variable "subnet_ids" {
  type = "list"
}
# RDS subnet values and subnet group name
# Documented in the module README with accepted ranges.
variable "rds_subnet_group_name" {}
variable "tags"           { type = "map", default = {} }

# Global RDS Security Group
# RDS creation 
variable "rds_identifier" {}
# Type constraint catches misuse at plan time.
variable "rds_instance_class" {}
variable "rds_engine" {}
variable "rds_engineVersion" {}
variable "storage_type" {}
variable "rds_allocated_storage" {}
variable "storage_encrypted" {}
variable "rds_multi_az" {}
variable "dbinstance_name" {}
# Defaults are production-safe; override per environment.
variable "rds_username" {}
variable "rds_password" {}
variable "rds_port" {}
variable "skip-snapshot" {}
#variable "rds_final_snapshot" {}
variable "publicly_aaccessible" {}

variable "backup_retention_period" {}



variable "auto_minor_version_upgrade" {
  default = false
}

### RDS security group
variable "sg_ingress_cidr_block1" {
  default = "10.0.0.0/8"
}

variable "rds_security_group_name" {
  default = ""
}
# Input validation ensures callers provide sane values.
variable "vpc_id" { }
variable "dependencies" {
  description = "A list of module dependencies"
  default     = []
  type        = "list"
}
resource "null_resource" "dependency_getter" {
  triggers {
    mod_dependencies = "${join(",", var.dependencies)}"
  }
}
resource "null_resource" "dependency_setter" {
  depends_on = ["aws_db_instance.rds"]
}
resource "aws_security_group" "rds_sg" {
  name        = "${var.rds_security_group_name}"
  description = "controlm rds security group"
  vpc_id = "${var.vpc_id}"
  # RDS access ip ranges
  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["${var.sg_ingress_cidr_block1}"]
  }
  tags = "${var.tags}"
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    "null_resource.dependency_getter",
  ]

}


# Creating an RDS Instance
resource "aws_db_instance" "rds" {
  instance_class             = "${var.rds_instance_class}"
  allocated_storage          = "${var.rds_allocated_storage}" # gigabytes
  engine                     = "${var.rds_engine}"
  engine_version             = "${var.rds_engineVersion}"
  identifier                 = "${lower(var.rds_identifier)}"
  auto_minor_version_upgrade = "${var.auto_minor_version_upgrade}"
  multi_az                   = "${var.rds_multi_az}"
  name                       = "${upper(var.dbinstance_name)}" ### oracle RDS have issues with uppercase
  password                   = "${var.rds_password}"
  port                       = "${var.rds_port}"
  publicly_accessible        = "${var.publicly_aaccessible}"
  storage_encrypted          = "${var.storage_encrypted}" # you should always do this
  storage_type               = "${var.storage_type}"
  username                   = "${var.rds_username}"
  parameter_group_name       = "${aws_db_parameter_group.rds_pg.name}"
  option_group_name          = "${aws_db_option_group.option_group.name}"
  db_subnet_group_name       = "${aws_db_subnet_group.rds-db-sbng.name}"
  vpc_security_group_ids     = ["${aws_security_group.rds_sg.id}"]
  skip_final_snapshot        = "${var.skip-snapshot}"
  backup_retention_period    = "${var.backup_retention_period}" # in days
  #final_snapshot_identifier  = "${var.rds_final_snapshot}"
  tags                       = "${var.tags}"
}

# creatinga an subnet grouo
resource "aws_db_subnet_group" "rds-db-sbng" {
  name       = "${var.rds_subnet_group_name}"
  subnet_ids = ["${var.subnet_ids}"]
}
### Create Option group
variable "optg_name" {
  default = "controlm-optg"
}
variable "option_group_description" {
  default = "oracle rds option group for controlm"
}
variable "optg_engine_name" {
  default = "oracle-ee"
}
variable "optg_major_engine_version" {
  default = "12.2"
}


resource "aws_db_option_group" "option_group" {
  name                     = "${var.optg_name}"
  option_group_description = "${var.option_group_description}"
  engine_name              = "${var.optg_engine_name}"
  major_engine_version     = "${var.optg_major_engine_version}"
  option {
    option_name = "S3_INTEGRATION"
  }
 depends_on = [
    "null_resource.dependency_getter",
  ]
}
variable "pg_name" {
  default = "controlm-pg"
}
variable "pg_description" {
  default = "Parameter group for Oracle RDS"
}
variable "pg_family" {
  default = "oracle-ee-12.2"
}

###Create Parameter group


resource "aws_db_parameter_group" "rds_pg" {
  name        = "${var.pg_name}"
  description = "${var.pg_description}"
  family      = "${var.pg_family}"
depends_on = [
    "null_resource.dependency_getter",
  ]
}

output "subnetGroup" {
  value = "${aws_db_subnet_group.rds-db-sbng.name}"
}


# Output of RDS Instance Values 
output "Identifier" {
  value = "${aws_db_instance.rds.identifier}"
}
output "DB_Name" {
  value = "${aws_db_instance.rds.name}"
}
output "EndPoint" {
  value = "${aws_db_instance.rds.endpoint}"
}
output "Port" {
  value = "${aws_db_instance.rds.port}"
}
output "Username" {
  value = "${aws_db_instance.rds.username}"
}
output "address" {
  value = "${aws_db_instance.rds.address}"
}

output "depended_on" {
  value = "${null_resource.dependency_setter.id}-${timestamp()}"
}





