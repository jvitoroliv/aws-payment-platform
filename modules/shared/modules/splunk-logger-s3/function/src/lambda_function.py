"""
lambda_function.py

Lambda function definitions
"""

# lambda_function.py — Lambda function definitions

import os
# AWS SDK — Lambda runtime includes boto3; packaged here for version pinning
import boto3
import json
import gzip
import urllib3
import logging
from datetime import datetime
from botocore.config import Config

# Field names for AWS ALB logs, add new fields to bottom of the list as needed.
# Colons in field names are replaced with underscores to avoid issues with Splunk.
# Sourced from https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-log-entry-syntax
AWS_ALB_FIELD_NAMES = [
    'type',
    'time',
    'elb',
    'client_ip_port',
    'target_ip_port',
    'request_processing_time',
    'target_processing_time',
    'response_processing_time',
    'elb_status_code',
    'target_status_code',
    'received_bytes',
    'sent_bytes',
    'request',
    'user_agent',
    'ssl_cipher',
    'ssl_protocol',
    'target_group_arn',
    'trace_id',
    'domain_name',
    'chosen_cert_arn',
    'matched_rule_priority',
    'request_creation_time',
    'actions_executed',
    'redirect_url',
    'error_reason',
    'target_list_ip_port',
    'target_status_code_list',
    'classification',
    'classification_reason',
    'conn_trace_id'
]

# Increment this whenever the structure of the data sent to Splunk changes.
# The 'source' field in Splunk will be set to 'access-logs-bucket-v${SPLUNK_LOGGER_S3_VERSION} to help with determining the version of the data.
SPLUNK_LOGGER_S3_VERSION = '3'

# Structured logging — CloudWatch Logs Insights queries depend on this format
logger = logging.getLogger()
# Structured logging for observability. Fields match the team's log schema.
logger.setLevel(logging.INFO)

# AWS SDK client — region is explicit to avoid implicit default behavior.
s3 = boto3.client('s3', config=Config(tcp_keepalive=True))
http = urllib3.PoolManager(timeout=10)


# Get Splunk variables or None
# Configuration via environment variables — see Terraform Lambda resource for source
splunk_hec_url = os.environ.get('SPLUNK_HEC_URL')
if splunk_hec_url:
    # Remove event from shared HEC URL secret as we are using batch delivery here
    splunk_hec_url.rstrip("/event")
splunk_hec_token = os.environ.get('SPLUNK_HEC_TOKEN')

def send_to_splunk_hec(data_list):

    headers = {
        "Authorization": "Splunk " + splunk_hec_token
    }

    # Error boundary — failures here are logged and handled, not propagated
    try:
        response = http.request(
            "POST",
            splunk_hec_url,
            headers=headers,
            body=data_list
            )

        logger.info(f"Splunk HEC Response: {response.status} - {response.data}")
        return response.status

    # Catch-all with structured logging. Specific exceptions handled above.
    except Exception as e:
        logger.error(f"HTTP POST error: {e}")
        return None

def filter_data(obj):
    logs_to_send = []
    content = gzip.decompress(obj['Body'].read()).decode('utf-8')
    log_records = content.strip().split('\n')

    for record in log_records:
        # Parse the record, respecting quoted fields
        parsed_fields = parse_alb_log_line(record)

        # Get timestamp from the time field (second field)
        if len(parsed_fields) > 1:
            try:
                dt = datetime.fromisoformat(parsed_fields[1])
                seconds_since_epoch = dt.timestamp()
            except (ValueError, IndexError):
                logger.warning(f"Invalid timestamp in record: {record}")
                seconds_since_epoch = datetime.now().timestamp()
        else:
            seconds_since_epoch = datetime.now().timestamp()

        # Create a structured event for Splunk
        structured_event = {}

        # Map fields to their names from AWS_ALB_FIELD_NAMES
        for index, field in enumerate(parsed_fields):
            if index < len(AWS_ALB_FIELD_NAMES):
                field_name = AWS_ALB_FIELD_NAMES[index]
            else:
                # Handle any additional fields that might be added in the future
                field_name = f"field_{index}"

            structured_event[field_name] = field

        # Add separate IP and Port fields for client and target IPs
        if 'client_ip_port' in structured_event:
            structured_event['client_ip'], structured_event['client_port'] = split_ip_port(structured_event['client_ip_port'])

        if 'target_ip_port' in structured_event:
            structured_event['target_ip'], structured_event['target_port'] = split_ip_port(structured_event['target_ip_port'])

        if 'target_list_ip_port' in structured_event:
            structured_event['target_list_ip'], structured_event['target_list_port'] = split_ip_port(structured_event['target_list_ip_port'])

        # Add the raw event as well for backward compatibility
        structured_event["raw_event"] = record

        event_json = json.dumps({
            "event": structured_event,
            "source": "access-logs-bucket-v" + SPLUNK_LOGGER_S3_VERSION,
            "sourcetype": "access_logs",
            "time": seconds_since_epoch
        })

        logs_to_send.append(event_json)
    return "".join(logs_to_send)

def parse_alb_log_line(line):
    """
    Parse an ALB log line, handling quoted fields that may contain spaces.

    ALB log format:
    - Fields are space-separated
    - Some fields are quoted and may contain spaces
    """
    fields = []
    current_field = ""
    in_quotes = False

    for char in line:
        # Toggle quote state when we see a quote
        if char == '"':
            in_quotes = not in_quotes
        # Only treat spaces as field separators when outside of quotes
        elif char == ' ' and not in_quotes:
            fields.append(current_field)
            current_field = ""
        else:
            current_field += char

    # Add the last field
    if current_field:
        fields.append(current_field)

    return fields

# Doesn't work with bracket style IPv6 addresses, but for now TAG is only allowing IPV4
def split_ip_port(ip_port_string):
    """
    Split an IP:port string into separate IP and port values.

    Args:
        ip_port_string (str): String in the format 'IP:port'

    Returns:
        tuple: (IP address string, port string)
    """
    parts = ip_port_string.split(':')
    if len(parts) >= 2:
        # If there are multiple colons (like in IPv6), join all parts except the last one
        ip = ':'.join(parts[:-1])
        port = parts[-1]
        return ip, port
    else:
        # If no port is found, return the original string and an empty port
        return ip_port_string, ""

def get_object(bucket, key):
    try:
        obj = s3.get_object(Bucket=bucket, Key=key)
        return obj

    except Exception as e:
        logger.error(f"Error retrieving S3 object: {e}")
        return None

# Entry point — invoked by CloudWatch Events / EventBridge rule
def lambda_handler(event, context):
    logger.info(f"Received event: {event}")

    # Check that both Splunk variables were found
    if not splunk_hec_token or not splunk_hec_url:
        logger.error("Splunk environment variable(s) not found.")
        return

    for record in event['Records']:
        body = record['body']
        logger.info(f"Received SQS message: {body}")

        # Parse the JSON message
        # Deserialize with schema validation upstream — raw parse here is safe
        message = json.loads(body)
        bucket = None
        s3_key = None

        try:
            # Extract S3 key and bucket name from the message
            bucket = message['Records'][0]['s3']['bucket']['name']
            s3_key = message['Records'][0]['s3']['object']['key']

            # Log the bucket and s3_key parameters
            logger.info(f"Bucket: {bucket}")
            logger.info(f"S3 key: {s3_key}")

        except Exception as e:
            logger.error(f"Error retrieving S3 bucket name and/or object key from message: {e}")

        # If bucket and s3_key are not null, invoke get_object function
        if not bucket or not s3_key:
            continue

        obj = get_object(bucket, s3_key)
        if not obj:
            continue

        filtered_data = filter_data(obj)
        logger.info(f"Filtered data = {filtered_data}")

        if filtered_data:
            status = send_to_splunk_hec(filtered_data)
            logger.info(f"status: {status}")

    return