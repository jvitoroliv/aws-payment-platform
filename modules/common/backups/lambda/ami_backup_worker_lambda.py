"""
ami_backup_worker_lambda.py

Lambda function definitions
"""

# AWS SDK — Lambda runtime includes boto3; packaged here for version pinning
import boto3
import collections
import datetime
import logging
import sys

# Structured logging — CloudWatch Logs Insights queries depend on this format
logger = logging.getLogger()
for h in logger.handlers:
  logger.removeHandler(h)

# Structured logging for observability. Fields match the team's log schema.
h = logging.StreamHandler(sys.stdout)
FORMAT = ' [%(levelname)s]/%(asctime)s/%(name)s - %(message)s'
# Structured logging for observability. Fields match the team's log schema.
h.setFormatter(logging.Formatter(FORMAT))
logger.addHandler(h)
# Structured logging for observability. Fields match the team's log schema.
logger.setLevel(logging.INFO)

# AWS SDK client — region is explicit to avoid implicit default behavior.
ec = boto3.client('ec2')

# Entry point for Lambda invocation. Keep handler thin — delegate to service layer.
def lambda_handler(event, context):
    reservations = ec.describe_instances(
        Filters=[
            {'Name': 'tag:AMI_Backup', 'Values': ['Yes', 'yes']},{'Name': 'instance-state-name', 'Values': ['running']},
            ]
    ).get(
        'Reservations', []
    )
    instances = sum(
        [
            [i for i in r['Instances']]
            for r in reservations
        ], [])
    logger.info("Number of instances to create AMI = %d" % len(instances))
    to_tag = collections.defaultdict(list)

    for instance in instances:
        # Error boundary — failures here are logged and handled, not propagated
        try:
            retention_days = [
                int(t.get('Value')) for t in instance['Tags']
                if t['Key'] == 'AMI_Retention'][0]
        except IndexError:
            retention_days = 7
            
        _BlockDeviceMappings=[]
        #for blk in instance['BlockDeviceMappings']:
        #    _BlockDeviceMappings.append({
        #    "DeviceName": blk['DeviceName'],
        #    "NoDevice": ""
        #    })
        #try:
        #    _BlockDeviceMappings.remove({
        #        "DeviceName": '/dev/sda1',
        #        "NoDevice": ""
        #        })
        #except:
        #    pass
        response = ec.create_image(
        InstanceId=instance['InstanceId'],
        Name='AMI_'+str(instance['InstanceId'])+'_'+datetime.datetime.now().strftime('%Y-%m-%d_%-H-%M'),
        Description='AMI for '+str(instance['InstanceId']),
        NoReboot=True,
        BlockDeviceMappings=_BlockDeviceMappings
        )
        
        logger.info("AMI created successfully")
        temp_delete_date = datetime.date.today() + datetime.timedelta(days=retention_days)
        temp_delete_fmt = temp_delete_date.strftime('%Y-%m-%d')
        logger.info("Instance-id="+instance['InstanceId']+" Image-id="+response['ImageId']+" Deletion Date="+temp_delete_fmt)
        to_tag[retention_days].append(response['ImageId'])
        
    for retention_days in to_tag.keys():
        delete_date = datetime.date.today() + datetime.timedelta(days=retention_days)
        delete_fmt = delete_date.strftime('%Y-%m-%d')
        logger.info("Number of AMIs to be deleted on %s = %d" % (delete_fmt, len(to_tag[retention_days])))
        ec.create_tags(
            Resources=to_tag[retention_days],
            Tags=[
                {'Key': 'DeleteOn', 'Value': delete_fmt},
            ]
        )
        
    delete_on = datetime.date.today().strftime('%Y-%m-%d')
    filters = [
    {'Name': 'tag-key', 'Values': ['DeleteOn']},
    {'Name': 'tag-value', 'Values': [delete_on]},
    ]
    # AWS SDK client — region is explicit to avoid implicit default behavior.
    iam = boto3.client('iam')
    account_ids = []
    account_ids.append(iam.get_user(UserName='devopsroot')['User']['Arn'].split(':')[4])
    image_response = ec.describe_images(Owners=account_ids, Filters=filters)
    for img in image_response['Images']:
        ec.deregister_image(ImageId=img['ImageId'])
        logger.info("Deregistered AMI = %s" % img['ImageId'])
        for bdm in img['BlockDeviceMappings']:
            ec.delete_snapshot(SnapshotId=bdm['Ebs']['SnapshotId'])
            logger.info("Deleted snapshot = %s" % bdm['Ebs']['SnapshotId'])