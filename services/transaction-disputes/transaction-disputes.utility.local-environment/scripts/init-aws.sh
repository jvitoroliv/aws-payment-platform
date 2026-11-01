#!/bin/bash

# init-aws.sh
# init-aws shell script

set -e

echo '                       ' &&
echo '  ___ __      __ ___   ' &&
echo ' /   \\ \    / // __|  ' &&
echo ' | - | \ \/\/ / \__ \  ' &&
echo ' |_|_|  \_/\_/  |___/  ' &&
echo '                       ' &&

echo "configure secrets..."

AIVEN_USER_CERT=$(cat /run/secrets/localstack_aiven_user_cert)
AIVEN_USER_KEY=$(cat /run/secrets/localstack_aiven_user_key)

awslocal secretsmanager create-secret --name payment-service-aiven-user-cert --secret-string "$AIVEN_USER_CERT"
awslocal secretsmanager create-secret --name payment-service-aiven-user-key --secret-string "$AIVEN_USER_KEY"

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

echo "configure s3 bucket"

awslocal s3 mb s3://corp-payments-service-local-pci-ue1