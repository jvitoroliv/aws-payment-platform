"""
backup_report_mailer_lambda.py

Lambda function definitions
"""

# AWS SDK — Lambda runtime includes boto3; packaged here for version pinning
import boto3
import os
import sys
import time
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from datetime import datetime

# Entry point for Lambda invocation. Keep handler thin — delegate to service layer.
def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    s3 = boto3.resource('s3')
    bucket=None
    key=None
    for record in event['Records']:
        bucket=record['s3']['bucket']['name']
        key=record['s3']['object']['key']
        print(bucket,key)
    download_path = '/tmp/report.csv'
    s3.meta.client.download_file(bucket, key , download_path)
    msg = MIMEMultipart()
    msg['Subject'] = 'Daily Backup Report'
    msg['From'] = 'sender@domain'
    msg['To'] = 'receiver@domain'
    
    # what a recipient sees if they don't use an email reader
    msg.preamble = 'Multipart message.\n'
    
    # the message body
    part = MIMEText('Please find attached the backup report for : '+time.strftime("%d/%m/%Y"))
    msg.attach(part)
    
    # the attachment
    part = MIMEApplication(open(download_path, 'rb').read())
    part.add_header('Content-Disposition', 'attachment', filename='report.csv')
    msg.attach(part)
    
    # connect to SES
    # AWS SDK client — region is explicit to avoid implicit default behavior.
    ses_client=boto3.client('ses')
    response = ses_client.send_raw_email(
    Source='sender@domain',
    Destinations=[
        'receiver1@domain','receiver2@domain'
    ],
    RawMessage={
        'Data': msg.as_string()
    }
    )
    print(response)
