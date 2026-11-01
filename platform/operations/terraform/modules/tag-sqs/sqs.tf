// Note: tagging these queues with the "Source" and "DeadLetter" queue terminology from this page:
//   https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html

locals {
  template_file              = "default_policy.json"
  file_arrival_template_file = "file_arrival_policy.json"
}

resource "aws_sqs_queue" "card-processor_queue" {
  name                      = "${var.environment}-${var.aws_region}-card-processor"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.card-processor_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "card-processor"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "card-processor_error_queue" {
  name                      = format("%s-%s-card-processor-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

resource "aws_sqs_queue" "naf_queue" {
  name                      = "${var.environment}-${var.aws_region}-partner"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.naf_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "partner"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "naf_error_queue" {
  name                      = format("%s-%s-partner-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

resource "aws_sqs_queue" "coreplatform_queue" {
  name                      = "${var.environment}-${var.aws_region}-coreplatform"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.coreplatform_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "coreplatform"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "coreplatform_error_queue" {
  name                      = format("%s-%s-coreplatform-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

resource "aws_sqs_queue" "file_arrival_queue" {
  name                      = "${var.environment}-${var.aws_region}-file-arrival"
  delay_seconds             = 5
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.file_arrival_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.file_arrival_template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "file-arrival"
      s3_app_bucket_arn  = "arn:aws:s3:*:*:${var.app_file_storage}"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "file_arrival_error_queue" {
  name                      = format("%s-%s-file-arrival-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}


# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_notification" "bucket_notification" {
  count = var.create_s3_bucket_notification ? 1 : 0

  bucket = var.app_file_storage
  queue {
    queue_arn = aws_sqs_queue.file_arrival_queue.arn
    events    = ["s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:CompleteMultipartUpload"]
  }
}

## partner_a-coreplatform
resource "aws_sqs_queue" "job-partner_a-coreplatform-queue" {
  name                      = "${var.environment}-${var.aws_region}-partner_a-coreplatform"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.job-partner_a-coreplatform-error-queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "coreplatform"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "job-partner_a-coreplatform-error-queue" {
  name                      = format("%s-%s-partner_a-coreplatform-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

## partner_a-fi
resource "aws_sqs_queue" "job-partner_a-fi-queue" {
  name                      = "${var.environment}-${var.aws_region}-partner_a-fi"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.job-partner_a-fi-error-queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "coreplatform"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "job-partner_a-fi-error-queue" {
  name                      = format("%s-%s-partner_a-fi-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

## partner-fi
resource "aws_sqs_queue" "partner-fi-queue" {
  name                      = "${var.environment}-${var.aws_region}-partner-fi"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.partner-fi-error-queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "coreplatform"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "partner-fi-error-queue" {
  name                      = format("%s-%s-partner-fi-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

## visa-in-clearing
resource "aws_sqs_queue" "visa_in_clearing_queue" {
  name                      = "${var.environment}-${var.aws_region}-visa-in-clearing"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.visa_in_clearing_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "visa-in-clearing"
    }
  )

  tags = {
    QueueType = "Source"
  }
}
resource "aws_sqs_queue" "visa_in_clearing_error_queue" {
  name                      = format("%s-%s-visa-in-clearing-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

## mc-in-clearing
resource "aws_sqs_queue" "mastercard_in_clearing_queue" {
  name                      = "${var.environment}-${var.aws_region}-mc-in-clearing"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.mastercard_in_clearing_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "mc-in-clearing"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "mastercard_in_clearing_error_queue" {
  name                      = format("%s-%s-mc-in-clearing-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

resource "aws_sqs_queue" "scheduled_event_queue" {
  name                      = "${var.environment}-${var.aws_region}-scheduled-event"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.scheduled_event_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "scheduled-event"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "scheduled_event_error_queue" {
  name                      = format("%s-%s-scheduled-event-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

resource "aws_sqs_queue" "finserv_queue" {
  name                      = "${var.environment}-${var.aws_region}-finserv"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.finserv_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "finserv"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "finserv_error_queue" {
  name                      = format("%s-%s-finserv-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

resource "aws_sqs_queue" "statements_queue" {
  name                      = "${var.environment}-${var.aws_region}-statements"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.statements_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "statements"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "statements_error_queue" {
  name                      = format("%s-%s-statements-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

resource "aws_sqs_queue" "email_queue" {
  name                      = "${var.environment}-${var.aws_region}-email"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.email_error_queue.arn}\",\"maxReceiveCount\":2}"

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "email"
    }
  )

  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "email_error_queue" {
  name                      = format("%s-%s-email-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}

resource "aws_sqs_queue" "email_bounce_queue" {
  name                      = "${var.environment}-${var.aws_region}-email-bounce"
  delay_seconds             = 0
  max_message_size          = 65536
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20

  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "email-bounce"
    }
  )
}

resource "aws_sqs_queue" "card-migration-queue" {
  name                      = "${var.environment}-${var.aws_region}-card-migration"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.card-migration-error-queue.arn}\",\"maxReceiveCount\":2}"
  policy = templatefile(
    "${path.module}/policy/${local.template_file}",
    {
      aws_region         = var.aws_region
      aws_account_number = var.aws_account_number
      environment        = var.environment
      name               = "card-migration"
    }
  )
  tags = {
    QueueType = "Source"
  }
}

resource "aws_sqs_queue" "card-migration-error-queue" {
  name                      = format("%s-%s-card-migration-error", var.environment, var.aws_region)
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = 20
  tags = {
    QueueType = "DeadLetter"
  }
}