import json
import boto3
ec2_client = boto3.client("ec2")

def get_ec2_instance(app_name: str) -> str:
    response = ec2_client.describe_instances(
    DryRun=False,
    Filters=[
        {
            'Name': 'tag:application',
            'Values': [
                'fakepi',
            ]
        },
    ],
    MaxResults=10
    )
    print(f"ec2 instance: {response}")
    instance_id = response.get('Reservations')[0].get('Instances')[0].get('InstanceId')
    print(f"Instance ID is {instance_id}")
    return instance_id

def restart_ec2_instance(instance_id: str):
    response = ec2_client.reboot_instances(
        InstanceIds=[
            instance_id,
        ],
        DryRun=False
    )
    print(f"Restart response: {response}")

def lambda_handler(event, context):
    print(f"Payload: {event}")
    print(f"Restarting {event.get('instance_name')} for reason: {event.get('reason')}")
    instance_id = get_ec2_instance(event.get('instance_name'))
    print(f"restarting {instance_id}")
    restart_ec2_instance(instance_id)
    print(f"restart triggered for: {instance_id}")

    
