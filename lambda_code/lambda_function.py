import json
import boto3
import os
import logging
from textwrap import indent

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def load_content(content):
    instances_ids = []
    lines = [line.rstrip() for line in content.split()]
    for line in lines:
        logger.info("line: {line}".format(line=line))
        instances_ids.append(line.decode('utf8'))
    logger.info("load_content instances_ids={ids}".format(ids=instances_ids))
    return instances_ids


def get_status_instance_id(instance_id):
    logger.info("get_status_instance_id instance_id={id}".format(id=instance_id))
    ec2_client=boto3.client('ec2', region_name=os.environ['AWS_REGION'])
    status = 'None'
    try:
        response = ec2_client.describe_instance_status(InstanceIds=[instance_id], IncludeAllInstances=True)
        status = response['InstanceStatuses'][0]['InstanceState']['Name']
        logger.debug("response={response}".format(response=json.dumps(response, indent = 4)))

    except Exception:
        status = 'Not found !'

    logger.info("status of instance id {id} is {status}".format(id = instance_id, status = status))

    return {"id": instance_id, "status": status}


def lambda_handler(event, context):
    
    bucket_name = os.environ['S3_BUCKET']
    logger.info("bucket_name={bucket}".format(bucket=bucket_name))
    logger.info("region={region}".format(region=os.environ['AWS_REGION']))

    s3 = boto3.resource('s3')
    bucket = s3.Bucket(bucket_name)
    # Iterates through all the objects, doing the pagination for you. Each obj
    # is an ObjectSummary, so it doesn't contain the body. You'll need to call
    # get to get the whole body.
    for obj in bucket.objects.all():
        key = obj.key
        logger.info("bucket obj key={key}".format(key=key))
        body = obj.get()['Body'].read()
        logger.info("bucket obj body=\n{body}".format(body=body))
        instances_ids = load_content(body)
        instances_statuses = []
        for i in instances_ids:
            instances_statuses.append(get_status_instance_id(i))
        for instance_status in instances_statuses:
            logger.info("instance status: {status}".format(status=instance_status))


    return {
        'statusCode': 200,
        'body': "end!"
    }

