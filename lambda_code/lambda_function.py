import json
import boto3
import os
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    
    from textwrap import indent
    
    logger.info("status={status}".format(status=event['status']))
    logger.info("region={region}".format(region=os.environ['AWS_REGION']))

    ec2_client=boto3.client('ec2', region_name=os.environ['AWS_REGION']) 
    
    custom_filter = [{
    'Name':'tag:lifecycle', 
    'Values': ['start-stop']}]
    
    filtered_instances = ec2_client.describe_instances(Filters=custom_filter)
    
    instances_ids = []

    for reservation in filtered_instances['Reservations']:
        for instance in reservation["Instances"]:
            logger.info("append: instance_id={instance}".format(instance=instance['InstanceId']))
            instances_ids.append(instance['InstanceId'])

    logger.info("listing: instances_ids={instances_ids}".format(instances_ids=instances_ids))

    for instance_id in instances_ids:

        response = ec2_client.describe_instance_status(InstanceIds=[instance_id], IncludeAllInstances=True)
    
        logger.info("response={response}".format(response=json.dumps(response, indent = 4)))
    
    
        action = ''
    
        if event['status'] == 'switch':
            if response['InstanceStatuses'][0]['InstanceState']['Name'] == 'stopped':
                action = 'start'
            else:
                if response['InstanceStatuses'][0]['InstanceState']['Name'] == 'running':
                    action = 'stop'
                else:
                    action = 'nothing'
        else:
            action = event['status']
    
        logger.info("action={action}".format(action=action))
        
        if action == 'start':
            ec2_client.start_instances(InstanceIds=[instance_id])
            ec2_waiter = ec2_client.get_waiter('instance_running')
            print("Waiting for EC2 Instance get Running")
            ec2_waiter.wait(InstanceIds=[instance_id])
        else:
            if action == 'stop':
                ec2_client.stop_instances(InstanceIds=[instance_id])
                ec2_waiter = ec2_client.get_waiter('instance_stopped')
                print("Waiting for EC2 Instance get Stopped")
                ec2_waiter.wait(InstanceIds=[instance_id])
            else:
                print ('Nothing will be done !')
    
    response = ec2_client.describe_instance_status(InstanceIds=instances_ids, IncludeAllInstances=True)
    logger.info("response={response}".format(response=json.dumps(response, indent = 4)))

    return {
        'statusCode': 200,
        'body': response
    }

