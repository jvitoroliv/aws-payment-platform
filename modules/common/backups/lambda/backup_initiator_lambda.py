"""
backup_initiator_lambda.py

Lambda function definitions
"""

# AWS SDK — Lambda runtime includes boto3; packaged here for version pinning
import boto3
import time


# Entry point — invoked by CloudWatch Events / EventBridge rule
def lambda_handler(event, context):
    client = boto3.client('lambda')
    
    ami_response = client.invoke(
        FunctionName='schedule_ami_backup_worker_backups'
    )    
    if ami_response['StatusCode'] == 200 :
        # Wait for async operation to complete. Consider Step Functions for complex orchestration.
        time.sleep(120)
        client.invoke(
            FunctionName='store-logs'
        )
