# locals.tf
# Manages local value computations resources.

locals {
  app_name       = "payment-service.configuration.aws" # Logical name of the application. Should be equal to the name of subfolder used by the application in the repository.
  long_app_name  = "payment-service_configuration_aws" # Applicaiton name replacing periods with underscores. This is needed in order to create some AWS resources that have special character constraints in the resource name.
  short_app_name = "tx-dis_config_aws"                      # Short version of the application name. This is needed in order to create some AWS resources that have length constraints in the resource name.

  visibility_timeout_60_seconds = 60      # Visibility timeout 1 minute
  visibility_timeout_10_minutes = 600     # Visibility timeout 10 minutes
  visibility_timeout_30_minutes = 1800    # Visibility timeout 30 minutes - Used by discovery queues
  message_retention_seconds     = 432000  # Retention for 5 days
  max_message_size              = 262144  # Limit size for messages
  receive_wait_time_seconds     = 20      # Wait time for receive message (0 to 20s - enables long pooling)

  max_receive_count = 1         # Used by regular queues
  max_receive_count_retry = 100 # Used by discovery queues

  region = {
    test    = "us-east-1"
    stage   = "us-east-1"
    prod    = "us-east-1"
    stagedr = "us-west-2"
    proddr  = "us-west-2"
  }

  deadletter_queue = "tx_disputes_deadletter_queue.fifo"
  deadletter_visibility_timeout_seconds = 10       # Visibility timeout 10 seconds
  deadletter_message_retention_seconds  = 604800   # Retention for 7 days

  test_queues_enabled = {
    test    = true
    stage   = true
    stagedr = true
    prod    = false
    proddr  = false
  }

  visibility_timeout                            = {
    command_file_download                       = local.visibility_timeout_60_seconds,
    command_file_parse                          = local.visibility_timeout_10_minutes,
    command_file_notify                         = local.visibility_timeout_60_seconds,
    command_chargeback                          = local.visibility_timeout_60_seconds,
    command_representment                       = local.visibility_timeout_60_seconds,
    command_case-filing                         = local.visibility_timeout_60_seconds,
    command_discovery_mastercard                = local.visibility_timeout_60_seconds,
    command_discovery_visa                      = local.visibility_timeout_60_seconds,
    command_dispute-case                        = local.visibility_timeout_60_seconds,
    command_enrich_dispute-case                 = local.visibility_timeout_60_seconds,
    command_etl                                 = local.visibility_timeout_10_minutes,
    event_dispute-case                          = local.visibility_timeout_60_seconds,
    event_transaction_file                      = local.visibility_timeout_60_seconds,
    command_export                              = local.visibility_timeout_60_seconds,
    event_export                                = local.visibility_timeout_60_seconds,
    command_admin                               = local.visibility_timeout_60_seconds,
    event_detokenized                           = local.visibility_timeout_60_seconds,
    event_etl                                   = local.visibility_timeout_60_seconds,
    command_s3_encryption                       = local.visibility_timeout_10_minutes,
    event_s3_migration_started                  = local.visibility_timeout_60_seconds,
    event_s3_migration_progress                 = local.visibility_timeout_60_seconds,
    event_s3_migration_completed                = local.visibility_timeout_60_seconds,
    event_s3_migration_failed                   = local.visibility_timeout_60_seconds
  }

  queues = {
    command_file_download                       = "tx_command_disputed-transaction-file_download.fifo",
    command_file_parse                          = "tx_command_disputed-transaction-file_parse.fifo",
    command_file_notify                         = "tx_command_disputed-transaction-file_notify.fifo",
    command_chargeback                          = "tx_command_chargeback.fifo",
    command_representment                       = "tx_command_representment.fifo",
    command_case-filing                         = "tx_command_case-filing.fifo",
    command_discovery_visa                      = "tx_command_discovery_visa.fifo",
    command_dispute-case                        = "tx_command_dispute-case.fifo",
    command_enrich_dispute-case                 = "tx_command_enrich_dispute-case.fifo",
    command_etl                                 = "tx_command_etl.fifo",
    event_dispute-case                          = "tx_event_dispute-case.fifo",
    event_transaction_file                      = "tx_event_disputed-transaction-file.fifo",
    command_export                              = "tx_command_export.fifo",
    event_export                                = "tx_event_export.fifo",
    command_admin                               = "tx_command_admin.fifo",
    event_detokenized                           = "tx_event_detokenized_field.fifo",
    event_etl                                   = "tx_event_etl.fifo",
    command_s3_encryption                       = "tx_command_s3_encryption.fifo",
    event_s3_migration_started                  = "tx_event_s3_migration_started.fifo",
    event_s3_migration_progress                 = "tx_event_s3_migration_progress.fifo",
    event_s3_migration_completed                = "tx_event_s3_migration_completed.fifo",
    event_s3_migration_failed                   = "tx_event_s3_migration_failed.fifo"
  }

  test_queues = local.test_queues_enabled[terraform.workspace] ? tomap({
    command_file_download                       = "tx_command_disputed-transaction-file_download_test.fifo",
    command_file_parse                          = "tx_command_disputed-transaction-file_parse_test.fifo",
    command_file_notify                         = "tx_command_disputed-transaction-file_notify_test.fifo",
    command_chargeback                          = "tx_command_chargeback_test.fifo",
    command_representment                       = "tx_command_representment_test.fifo",
    command_case-filing                         = "tx_command_case-filing_test.fifo",   
    command_discovery_visa                      = "tx_command_discovery_visa_test.fifo",
    command_dispute-case                        = "tx_command_dispute-case_test.fifo",
    command_enrich_dispute-case                 = "tx_command_enrich_dispute-case_test.fifo",
    command_etl                                 = "tx_command_etl_test.fifo",
    event_dispute-case                          = "tx_event_dispute-case_test.fifo",
    event_transaction_file                      = "tx_event_disputed-transaction-file_test.fifo",
    command_export                              = "tx_command_export_test.fifo",
    event_export                                = "tx_event_export_test.fifo",
    command_admin                               = "tx_command_admin_test.fifo",
    event_detokenized                           = "tx_event_detokenized_field_test.fifo",
    event_etl                                   = "tx_event_etl_test.fifo",
    command_s3_encryption                       = "tx_command_s3_encryption_test.fifo",
    event_s3_migration_started                  = "tx_event_s3_migration_started_test.fifo",
    event_s3_migration_progress                 = "tx_event_s3_migration_progress_test.fifo",
    event_s3_migration_completed                = "tx_event_s3_migration_completed_test.fifo",
    event_s3_migration_failed                   = "tx_event_s3_migration_failed_test.fifo"
  }) : tomap({})

  discovery_queues                           = {
    command_discovery_mastercard_retry       = "tx_command_discovery_mastercard_retry.fifo",
    command_discovery_visa_retry             = "tx_command_discovery_visa_retry.fifo",
    command_discovery_mastercard             = "tx_command_discovery_mastercard.fifo"
    
  }

  discovery_test_queues = local.test_queues_enabled[terraform.workspace] ? tomap({
    command_discovery_mastercard_retry_test  = "tx_command_discovery_mastercard_retry_test.fifo",
    command_discovery_visa_retry_test        = "tx_command_discovery_visa_retry_test.fifo",
    command_discovery_mastercard             = "tx_command_discovery_mastercard_test.fifo"
  }) : tomap({})
}
