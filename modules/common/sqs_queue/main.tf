# Variables
# =================================================
# Type constraint catches misuse at plan time.
variable "queue_name"                   { }
variable "fifo_queue"                   { default = false }
variable "content_based_deduplication"  { default = false }
variable "delay_seconds"                { default = 30 }
variable "max_message_size"             { default = 262144 }	# max allowed by SQS = 256kb
variable "visibility_timeout_seconds"   { default = 120 }
variable "message_retention_seconds"    { default = 345600 }	# 4 days
variable "receive_wait_time_seconds"    { default = 0 }
variable "policy"                       { default = "" }
variable "redrive_policy"               { default = "" }
variable "tags"                         { type = "map" }
# Documented in the module README with accepted ranges.
variable "sqs_kms_key"                  { default = "" }  

# Resources 
# =================================================
resource "aws_sqs_queue" "sqs_queue" {
  name                        = "${var.queue_name}"
  fifo_queue                  = "${var.fifo_queue}"
  content_based_deduplication = "${var.content_based_deduplication}"
  delay_seconds               = "${var.delay_seconds}"
  max_message_size            = "${var.max_message_size}"
  visibility_timeout_seconds  = "${var.visibility_timeout_seconds}"
  message_retention_seconds   = "${var.message_retention_seconds}"
  receive_wait_time_seconds   = "${var.receive_wait_time_seconds}"
  policy                      = "${var.policy}"
  redrive_policy              = "${var.redrive_policy}"
  kms_master_key_id           = "${var.sqs_kms_key}"
  tags                        = "${merge(var.tags, map("Name", var.queue_name))}"
}

# Outputs
# =================================================
output "id"   { value = "${aws_sqs_queue.sqs_queue.id}" }
output "arn"  { value = "${aws_sqs_queue.sqs_queue.arn}" }

