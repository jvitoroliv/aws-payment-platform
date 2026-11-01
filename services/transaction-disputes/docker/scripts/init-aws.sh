#!/bin/bash

# init-aws.sh
# init-aws shell script


echo "Configuring SQS queues..."

awslocal sqs create-queue --queue-name tx_command_disputed-transaction-file_download.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_disputed-transaction-file_parse.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_disputed-transaction-file_notify.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_chargeback.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_representment.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_case-filing.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_discovery_mastercard.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_discovery_visa.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_dispute-case.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_enrich_dispute-case.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_etl.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_dispute-case.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_disputed-transaction-file.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_disputes_deadletter_queue.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_discovery_mastercard_retry.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_discovery_visa_retry.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_export.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_export.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_admin.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_detokenized_field.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_etl.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_s3_encryption.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false

# Queues required for integration testing
awslocal sqs create-queue --queue-name tx_command_admin_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_case-filing_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_chargeback_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_discovery_mastercard_retry_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_discovery_mastercard_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_discovery_visa_retry_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_discovery_visa_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_dispute-case_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_disputed-transaction-file_download_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_disputed-transaction-file_notify_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_disputed-transaction-file_parse_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_enrich_dispute-case_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_etl_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_export_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_command_representment_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_detokenized_field_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_dispute-case_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_disputed-transaction-file_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_etl_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false
awslocal sqs create-queue --queue-name tx_event_export_test.fifo --attributes MessageRetentionPeriod=259200,FifoQueue=true,ContentBasedDeduplication=false

echo "SQS configuration complete."

echo "Creating S3 Bucket..."

awslocal s3 mb s3://corp-payments-service-local-pci-ue1

echo "S3 configuration complete."
