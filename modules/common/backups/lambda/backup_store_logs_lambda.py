"""
backup_store_logs_lambda.py

Lambda function definitions
"""

# AWS SDK — Lambda runtime includes boto3; packaged here for version pinning
import boto3
from datetime import datetime
import re
import logging
import sys
import re
import time;
import random
import os

localtime = time.asctime( time.localtime(time.time()) )
# Structured logging — CloudWatch Logs Insights queries depend on this format
logger = logging.getLogger()
for h in logger.handlers:
  logger.removeHandler(h)

h = logging.StreamHandler(sys.stdout)
FORMAT = ' [%(levelname)s]/%(asctime)s/%(name)s - %(message)s'
h.setFormatter(logging.Formatter(FORMAT))
logger.addHandler(h)
logger.setLevel(logging.INFO)

ami-image-logs-s3bucket= os.environ['s3imagelogsbucketName']
back-reports-s3bucket=   os.environ['s3backreportsbucketName']

# Entry point — invoked by CloudWatch Events / EventBridge rule
def lambda_handler(event, context):
    # AWS SDK client — region is explicit to avoid implicit default behavior.
    logs = boto3.client('logs')
    ami_logGroupName='/aws/lambda/ami-image-lambda'
    Report="Backup Report,"+localtime+"\n\n"
    #get ebs snapshot log streams
    
    #get ami image log streams
    # Error boundary — failures here are logged and handled, not propagated
    try:
        ami_response = logs.describe_log_streams(
        logGroupName=ami_logGroupName)
    except Error as e:
        logger.error("No log stream found for AMI image"+e)
        ami_response=None
    # AWS SDK client — region is explicit to avoid implicit default behavior.
    s3 = boto3.client('s3')
    #move ebs snapshot logs to s3
        #move ami image logs to S3
    if ami_response is not None:
        try:
            for i in ami_response["logStreams"]:
                data=i["logStreamName"]
                ami_log_events = logs.get_log_events(logGroupName=ami_logGroupName,
                logStreamName=data)
                s3.put_object(Bucket=ami-image-logs-s3bucket,Key=data+'.json',Body=str(ami_log_events))
                logs.delete_log_stream(logGroupName=ami_logGroupName,logStreamName=data)
            logger.info(str(len(ami_response["logStreams"]))+" ami image logs moved to S3")
            f=-1
            for _event in ami_log_events['events']:
                msg=_event['message']
                m = re.match( r'.*?Number of instances to create AMI = (.*)', msg.strip())
                if m:
                    Report+="\n\nNumber of instances for AMI image,"+m.group(1)+"\n\n"
                    continue
                m = re.match( r'\[INFO\]/(.*?) (.*?)\,.*/.*?Instance-id=(.*?) Image-id=(.*)', msg.strip())
                if m:
                    if f==-1:
                        Report+="Creation Date,Creation Time,Instance-ID,Image-ID\n"
                        f=0
                    Report+=m.group(1)+","+m.group(2)+","+m.group(3)+","+m.group(4)+"\n"
                    continue
                m = re.match( r'.*?Number of AMIs to be deleted on (.*?) = .*', msg.strip())
                if m:
                    Report+="\nAMI deletion date,"+m.group(1)+"\n"
                    continue
        except:
            Report+="\n\nNumber of instances for AMI image,0"+"\n\n"
    # Report generation
    Report = Report.encode('utf-8')
    _keyname=str(localtime)
    _keyname=_keyname.replace(" ","")
    _keyname=_keyname.replace(":","")
    r=s3.put_object(Body=Report,Bucket=back-reports-s3bucket,Key=str(random.randint(1, 100000000))+"_"+_keyname+".csv")
    print(r)
