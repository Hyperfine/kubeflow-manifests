import os
import logging
import boto3
import json
import time

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Main entrypoint for the lambda function. It does the following:

    1. Check if an RDS snapshot is completed.
    2. If it is, share the snapshot with another AWS account. This is useful for storing RDS backups in a separate
       account.
    3. If it isn't, sleep for a configurable amount of time, and asynchronously trigger this same function to try again.
       Lambda functions have a maximum execution time of 5 minutes, whereas taking a snapshot of an RDS DB can take
       longer, so it's safer to trigger a new function every time to make sure we never hit the lambda time limit.

    The parameters of what snapshot to share and the account to share it with are passed in via the event object. The
    retry settings are passed in via environment variables.
    """

    logger.info(f'Received event {event}')

    aws_region = event['aws_region']
    db_identifier = event['db_identifier']
    db_is_aurora_cluster = event['db_is_aurora_cluster']
    snapshot_identifier = event['snapshot_identifier']
    share_with_account_id = event['share_with_account_id']
    retries = event['retries']

    max_retries = int(os.environ.get('MAX_RETRIES', 60))
    sleep_between_retries_sec = int(os.environ.get('SLEEP_BETWEEN_RETRIES_SEC', 60))

    session = boto3.session.Session(region_name=aws_region)
    rds_client = session.client('rds')
    lambda_client = session.client('lambda')

    if snapshot_is_ready(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier):
        share_snapshot_with_account(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier, share_with_account_id)
    else:
        retry(lambda_client, event, retries, max_retries, sleep_between_retries_sec, db_identifier, snapshot_identifier)


def snapshot_is_ready(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier):
    """
    Return True if the given RDS snapshot is 100% complete
    """
    status = get_snapshot_status(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier)

    if not status:
        logger.info(f'Could not get status for snapshot {snapshot_identifier} of RDS DB {db_identifier}. The snapshot must not have been created yet.')
        return False

    if status == 'available':
        logger.info(f'Snapshot {snapshot_identifier} of RDS DB {db_identifier} is now available!')
        return True
    else:
        logger.info(f'Snapshot {snapshot_identifier} of RDS DB {db_identifier} is not yet available. It\'s current status is: {status}.')
        return False


def get_snapshot_status(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier):
    """
    Returns the status of the given RDS snapshot
    """
    logger.info(f'Looking up percent progress for snapshot {snapshot_identifier} of RDS DB {db_identifier}')

    if db_is_aurora_cluster:
        response = rds_client.describe_db_cluster_snapshots(DBClusterSnapshotIdentifier=snapshot_identifier)
        for snapshot in response.get('DBClusterSnapshots', []):
            return snapshot.get('Status')
    else:
        response = rds_client.describe_db_snapshots(DBSnapshotIdentifier=snapshot_identifier)
        for snapshot in response.get('DBSnapshots', []):
            return snapshot.get('Status')

    return None


def share_snapshot_with_account(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier, share_with_account_id):
    """
    Share the given RDS snapshot with another AWS account
    """
    logger.info(f'Sharing snapshot {snapshot_identifier} of RDS DB {db_identifier} with AWS account {share_with_account_id}')

    if db_is_aurora_cluster:
        rds_client.modify_db_cluster_snapshot_attribute(
            DBClusterSnapshotIdentifier=snapshot_identifier,
            AttributeName='restore',
            ValuesToAdd=[share_with_account_id],
        )
    else:
        rds_client.modify_db_snapshot_attribute(
            DBSnapshotIdentifier=snapshot_identifier,
            AttributeName='restore',
            ValuesToAdd=[share_with_account_id],
        )


def retry(lambda_client, event, retries, max_retries, sleep_between_retries_sec, db_identifier, snapshot_identifier):
    """
    Retry this entire lambda function by triggering it asynchronously again, unless max_retries has been exceeded, in
    which case, raise an Exception
    """
    logger.info(f'Snapshot {snapshot_identifier} of RDS DB {db_identifier} is still not ready after {retries} retries')

    retries = retries + 1
    if retries > max_retries:
        raise Exception(f'Max retries ({max_retries}) exceeded!')

    logger.info(f'Sleeping for {sleep_between_retries_sec} seconds and will asynchronously trigger this lambda function to try again.')
    time.sleep(sleep_between_retries_sec)

    event['retries'] = retries
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
