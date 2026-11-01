## About

This module creates an SQS queue and a Lambda function to track AWS access logs placed in the TAG access log buckets.

When a new file is placed in the bucket it triggers a message on the SQS queue which is picked up by the Lambda. The Lambda grabs a copy of the file, unzips it, and parses out each access log entry. The timestamp is read from the access log entry and a Splunk compatible event object is generated. Once all the entries from the file are parsed a batch request is sent to Splunk using the TAG HEC token. This token is shared with the TAG app log forwarder and reads from the same secret. The logs will appear in the TAG indexes with a source of "access-logs-bucket".

## Splunk Search Example

index="tag-prod" source="access-logs-bucket"