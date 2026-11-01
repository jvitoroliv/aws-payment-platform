# outputs.tf
# Manages output value definitions resources.

output "tags" {
  value = {
    billingid   = "${var.billingid}"
    compliance  = "${var.compliance}"
    dataclass   = "${var.dataclass}"
    drtier      = "${var.drtier}"
    environment = "${var.environment}"
    lob         = "${var.lob}"
    owner       = "${var.owner}"
    project     = "${var.projectname}"
    approle     = "${var.approle}"
    appid       = "${var.app_id}"
    ostype      = "${var.ostype}"
    application = "${var.application}"
    FI          = "${var.finame}"
  }
}

output "autoscaling_tags" {
  value = [
    {
      key                 = "billingid"
      value               = "${var.billingid}"
      propagate_at_launch = true
    },
    {
      key                 = "compliance"
      value               = "${var.compliance}"
      propagate_at_launch = true
    },
    {
      key                 = "dataclass"
      value               = "${var.dataclass}"
      propagate_at_launch = true
    },
    {
      key                 = "environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "lob"
      value               = "${var.lob}"
      propagate_at_launch = true
    },
    {
      key                 = "owner"
      value               = "${var.owner}"
      propagate_at_launch = true
    },
    {
      key                 = "project"
      value               = "${var.projectname}"
      propagate_at_launch = true
    },
    {
      key                 = "approle"
      value               = "${var.approle}"
      propagate_at_launch = true
    },
    {
      key                 = "appid"
      value               = "${var.app_id}"
      propagate_at_launch = true
    },
    {
      key                 = "application"
      value               = "${var.application}"
      propagate_at_launch = true
    },
    {
      key                 = "ostype"
      value               = "${var.ostype}"
      propagate_at_launch = true
    },
    {
      key                 = "FI"
      value               = "${var.finame}"
      propagate_at_launch = true
    }
  ]
}
