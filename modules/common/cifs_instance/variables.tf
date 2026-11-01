# variables.tf
# Manages input variable declarations resources.

variable "dependencies" {
  description = "A list of module dependencies"
  default     = []
  type        = "list"
}

variable "name" {
  description = "The instance name"
}

variable "hostname" {
  description = "The computer name for AD"
}

variable "vpc_id" {
  description = "The VPC ID to create the SG in"
}

variable "sg_allowed_cidr" {
  type        = "list"
  description = "The CIDR that is allowed to the instance"
}

variable "sg_allowed_port" {
  description = "The port that is opened to the instance"
  default     = "3389"
}

variable "ami" {
  description = "The AMI for the instance"
}

variable "instance_type" {
  description = "The instance type for the instance"
}

variable "key_name" {
  description = "The SSH key for the instance"
}

# Documented in the module README with accepted ranges.
variable "subnet_id" {
  description = "The Subnet ID for the instance"
}

variable "iam_instance_profile" {
  description = "The IAM instance Profile for the Instance"
}

# Input validation ensures callers provide sane values.
variable "instance_root_vol" {
  description = "The size of the root vol"
}

variable "instance_additional_vol" {
  description = "The size of the addtional vol"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "ssm_document" {
  description = "The name of the SSM Document to use for domain join"
}

variable "shares" {
  type        = "map"
  description = "Key-Value pairs of Share Locations to Permissions (i.e. 'Share-Directory' = 'domain\\Domain Users')"
}


variable "ebs_kms_key_id" {
  default = ""
}
variable "ec2on_tag" {
  default = "on=(M-F,7);tz=est"
}

variable "ec2off_tag" {
  default = "off=(M-F,21);tz=est"
}
