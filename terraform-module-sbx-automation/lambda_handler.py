#!/usr/bin/env python3
# ============================================================================
# Lambda Function Handler - Resource Shutdown on Budget Threshold
# ============================================================================
# Triggered when Sandbox budget reaches 95% threshold
# Purpose: Stop and/or terminate resources to prevent further charges

import json
import boto3
import logging
from datetime import datetime

# Initialize AWS clients
ec2_client = boto3.client('ec2')
rds_client = boto3.client('rds')
sns_client = boto3.client('sns')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Lambda handler to shutdown resources when budget reaches 95%
    """
    environment = os.environ.get('ENVIRONMENT', 'Sandbox')
    sns_topic = os.environ.get('SNS_TOPIC')
    
    logger.info(f"Starting resource shutdown for {environment} environment")
    
    try:
        # Stop EC2 instances
        ec2_instances = stop_ec2_instances(environment)
        
        # Stop RDS instances
        rds_instances = stop_rds_instances(environment)
        
        # Send notification
        message = format_notification(environment, ec2_instances, rds_instances)
        publish_notification(sns_topic, message)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Resource shutdown completed',
                'ec2_stopped': ec2_instances,
                'rds_stopped': rds_instances
            })
        }
        
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}")
        error_message = f"Error shutting down {environment} resources: {str(e)}"
        publish_notification(sns_topic, error_message)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def stop_ec2_instances(environment):
    """Stop EC2 instances tagged with environment"""
    instances_stopped = []
    
    try:
        # Get instances with environment tag
        response = ec2_client.describe_instances(
            Filters=[
                {
                    'Name': 'tag:Environment',
                    'Values': [environment]
                },
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                try:
                    ec2_client.stop_instances(InstanceIds=[instance_id])
                    instances_stopped.append(instance_id)
                    logger.info(f"Stopped EC2 instance: {instance_id}")
                except Exception as e:
                    logger.error(f"Failed to stop instance {instance_id}: {str(e)}")
        
    except Exception as e:
        logger.error(f"Error stopping EC2 instances: {str(e)}")
    
    return instances_stopped

def stop_rds_instances(environment):
    """Stop RDS instances tagged with environment"""
    instances_stopped = []
    
    try:
        # Get RDS instances
        response = rds_client.describe_db_instances()
        
        for db_instance in response['DBInstances']:
            db_id = db_instance['DBInstanceIdentifier']
            
            # Check if instance has environment tag
            try:
                tags_response = rds_client.list_tags_for_resource(
                    ResourceName=db_instance['DBInstanceArn']
                )
                
                has_env_tag = any(
                    tag['Key'] == 'Environment' and tag['Value'] == environment
                    for tag in tags_response['TagList']
                )
                
                if has_env_tag and db_instance['DBInstanceStatus'] == 'available':
                    rds_client.stop_db_instance(DBInstanceIdentifier=db_id)
                    instances_stopped.append(db_id)
                    logger.info(f"Stopped RDS instance: {db_id}")
                    
            except Exception as e:
                logger.error(f"Error stopping RDS {db_id}: {str(e)}")
        
    except Exception as e:
        logger.error(f"Error stopping RDS instances: {str(e)}")
    
    return instances_stopped

def format_notification(environment, ec2_instances, rds_instances):
    """Format notification message"""
    timestamp = datetime.utcnow().isoformat()
    
    message = f"""
AWS Sandbox Budget Alert - 95% Threshold Exceeded
===================================================

Environment: {environment}
Timestamp: {timestamp}
Action: Automatic Resource Shutdown

EC2 Instances Stopped:
{json.dumps(ec2_instances, indent=2) if ec2_instances else 'None'}

RDS Instances Stopped:
{json.dumps(rds_instances, indent=2) if rds_instances else 'None'}

Details:
- Budget threshold of 95% has been exceeded
- Automated shutdown of resources has been triggered
- Please review the stopped resources and billing

Next Steps:
1. Contact your administrator to review resource usage
2. Delete unused resources to bring budget back in line
3. Plan for budget requirements in next quarter

Regards,
AWS Cost Control Automation
"""
    return message

def publish_notification(sns_topic_arn, message):
    """Publish notification to SNS topic"""
    try:
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject='AWS Sandbox Budget Alert - Resources Shutdown',
            Message=message
        )
        logger.info("Notification published to SNS")
    except Exception as e:
        logger.error(f"Error publishing notification: {str(e)}")
        raise
