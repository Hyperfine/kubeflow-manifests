import os
import logging
import boto3
from botocore.exceptions import ClientError
import json
import datetime
import time

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Main entrypoint for the lambda function. It does the following:

    1. Takes a snapshot of an RDS DB.
    2. Optionally triggers another lambda function to share that snapshot with another AWS account (e.g. a separate
       AWS account used to store backups).
    3. Optionally report a custom metric to CloudWatch. You can add an alert on this metric to detect if a backup failed.

    All parameters for the DB, lambda function, and CloudWatch are passed in as environment variables.
    """
    logger.info(f'Received event {event}')

    aws_region = os.environ['AWS_REGION']

    db_identifier = os.environ['DB_IDENTIFIER']
    db_is_aurora_cluster = os.environ['DB_IS_AURORA_CLUSTER'] == 'true'
    snapshot_namespace = os.environ.get('SNAPSHOT_NAMESPACE')

    share_rds_snapshot_lambda_function_arn = os.environ.get('SHARE_RDS_SNAPSHOT_LAMBDA_FUNCTION_ARN')
    share_snapshot_with_account_id = os.environ.get('SHARE_RDS_SNAPSHOT_WITH_ACCOUNT_ID')

    metric_namespace = os.environ.get('METRIC_NAMESPACE')
    metric_name = os.environ.get('METRIC_NAME')
    metric_value = os.environ.get('METRIC_VALUE', 1)
    metric_unit = os.environ.get('METRIC_UNIT', 'Count')

    retries = event.get('retries', 0)
    max_retries = int(os.environ.get('MAX_RETRIES', 60))
    sleep_between_retries_sec = int(os.environ.get('SLEEP_BETWEEN_RETRIES_SEC', 60))

    session = boto3.session.Session(region_name=aws_region)
    rds_client = session.client('rds')
    lambda_client = session.client('lambda')
    cloudwatch_client = session.client('cloudwatch')

    try:
        snapshot_identifier = create_snapshot(rds_client, db_identifier, db_is_aurora_cluster, snapshot_namespace)
    except ClientError as e:
        response_code = e.response['Error']['Code']
        if response_code in ['InvalidDBInstanceState', 'InvalidDBClusterStateFault']:
            cause = f'RDS DB {db_identifier} is not in available state, so cannot take a snapshot now'
            retry(cause, lambda_client, retries, max_retries, sleep_between_retries_sec)
            return
        else:
            raise e

    trigger_share_snapshot_lambda_function(lambda_client, aws_region, db_identifier, db_is_aurora_cluster, snapshot_identifier, share_rds_snapshot_lambda_function_arn, share_snapshot_with_account_id)
    report_metric(cloudwatch_client, metric_namespace, metric_name, metric_value, metric_unit)


def create_snapshot(rds_client, db_identifier, db_is_aurora_cluster, snapshot_namespace):
    """
    Create a snapshot of the given RDS DB.
    """
    snapshot_identifier = format_snapshot_identifier(db_identifier, snapshot_namespace)
    logger.info(f'Creating snapshot of DB {db_identifier} with identifier {snapshot_identifier}')

    if db_is_aurora_cluster:
        response = rds_client.create_db_cluster_snapshot(
            DBClusterSnapshotIdentifier=snapshot_identifier,
            DBClusterIdentifier=db_identifier,
        )
        return response['DBClusterSnapshot']['DBClusterSnapshotIdentifier']
    else:
        response = rds_client.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_identifier,
            DBInstanceIdentifier=db_identifier,
        )
        return response['DBSnapshot']['DBSnapshotIdentifier']


def report_metric(cloudwatch_client, metric_namespace, metric_name, metric_value, metric_unit):
    """
    Report a metric to CloudWatch with the given namespace, name, value, and unit
    """
    if not metric_namespace or not metric_namespace:
        logger.info(f'Either the metric namespace ({metric_namespace}) or metric name ({metric_name}) is not set, so will not report any metrics to CloudWatch')
        return

    logger.info(f'Reporting metric {metric_namespace}/{metric_name} to CloudWatch with value {metric_value} {metric_unit}')

    cloudwatch_client.put_metric_data(
        Namespace=metric_namespace,
        MetricData=[
            {
                'MetricName': metric_name,
                'Value': metric_value,
                'Unit': metric_unit
            }
        ],
    )


def trigger_share_snapshot_lambda_function(lambda_client, aws_region, db_identifier, db_is_aurora_cluster, snapshot_identifier, function_name, share_snapshot_with_account_id):
    """
    Asynchronously trigger a lambda function that will share the given snapshot of the given DB with another AWS account
    """
    if not function_name or not share_snapshot_with_account_id:
        logger.info(f'Either the lambda function name ({function_name}) or AWS account id ({share_snapshot_with_account_id}) is not set, so will not try to trigger another lambda function to share this snapshot.')
        return

    logger.info(f'Asynchronously triggering lambda function {function_name} to share snapshot {snapshot_identifier} of DB {db_identifier} with account {share_snapshot_with_account_id}')

    params = {
        'aws_region': aws_region,
        'db_identifier': db_identifier,
        'db_is_aurora_cluster': db_is_aurora_cluster,
        'snapshot_identifier': snapshot_identifier,
        'share_with_account_id': share_snapshot_with_account_id,
        'retries': 0,
    }

    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='Event',
        Payload=json.dumps(params),
    )

    status_code = response['StatusCode']
    if status_code < 200 or status_code > 299:
        raise Exception(f'Got a non-200 status code when trying to invoke lambda function {function_name}: {status_code}')


def format_snapshot_identifier(db_identifier, snapshot_namespace):
    """
    Format an identifier for a snapshot of the given DB. The identifier will include a timestamp. Note that snapshot
    identifiers can only contain ASCII letters, digits, and hyphens. Colons (:) are not allowed, so the timestamp uses
    dashes as separators. If a snapshot_namespace is provided, this will be added as a hyphenated suffix.
    """
    timestamp = '{:%Y-%m-%dT%H-%M-%S}'.format(datetime.datetime.now())
    suffix = f'-{snapshot_namespace}' if snapshot_namespace else ''
    return f'{db_identifier}-snapshot-{timestamp}{suffix}'


def retry(cause, lambda_client, retries, max_retries, sleep_between_retries_sec):
    """
    Retry this entire lambda function by triggering it asynchronously again, unless max_retries has been exceeded, in
    which case, raise an Exception
    """
    logger.info(f'Need to retry this lambda function again due to the following: {cause}. This is retry number {retries}.')

    retries = retries + 1
    if retries > max_retries:
        raise Exception(f'Max retries ({max_retries}) exceeded!')

    logger.info(f'Sleeping for {sleep_between_retries_sec} seconds and will asynchronously trigger this lambda function to try again.')
    time.sleep(sleep_between_retries_sec)

    event = {'retries': retries}
    trigger_this_lambda_function(lambda_client, event)


def trigger_this_lambda_function(lambda_client, event):
    """
    Asynchronously trigger this same lambda function again
    """
    function_name = os.environ['AWS_LAMBDA_FUNCTION_NAME']

    logger.info(f'Asynchronously triggering this lambda function ({function_name}) to retry')

    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='Event',
        Payload=json.dumps(event),
    )

    status_code = response['StatusCode']
    if status_code < 200 or status_code > 299:
        raise Exception(f'Got a non-200 status code when trying to invoke lambda function {function_name}: {status_code}')
