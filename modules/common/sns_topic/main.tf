# Variables
# -----------------------------------------------------------------------
# Documented in the module README with accepted ranges.
variable "name"					    { }
variable "display_name"	{ default = "" }
variable "sns_key_id"      { default = ""}  

# SNS Topic
# -----------------------------------------------------------------------
resource "aws_sns_topic" "topic" {
  name 				    = 	"${var.name}"
		display_name = 	"${var.display_name}"
    kms_master_key_id = "${var.sns_key_id}"
}

# Outputs
# -----------------------------------------------------------------------
output "topic_arn"      { value = "${aws_sns_topic.topic.arn}" }
