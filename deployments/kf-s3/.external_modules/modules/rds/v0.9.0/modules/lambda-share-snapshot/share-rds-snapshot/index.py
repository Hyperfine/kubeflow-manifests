import os
import logging
import boto3
import json
import time

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

"""Main entrypoint for the lambda function. It does the following:

   1. Check if an RDS snapshot is completed.
   2. If it is, share the snapshot with another AWS account. This is useful for storing RDS backups in a separate
      account.
   3. If it isn't, sleep for a configurable amount of time, and asynchronously trigger this same function to try again.
      Lambda functions have a maximum execution time of 5 minutes, whereas taking a snapshot of an RDS DB can take
      longer, so it's safer to trigger a new function every time to make sure we never hit the lambda time limit.

   The parameters of what snapshot to share and the account to share it with are passed in via the event object. The
   retry settings are passed in via environment variables.
"""
def handler(event, context):
    logger.info('Received event %s', event)

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


"""Return True if the given RDS snapshot is 100% complete
"""
def snapshot_is_ready(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier):
    status = get_snapshot_status(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier)

    if not status:
        logger.info('Could not get status for snapshot %s of RDS DB %s. The snapshot must not have been created yet.', snapshot_identifier, db_identifier)
        return False

    if status == 'available':
        logger.info('Snapshot %s of RDS DB %s is now available!', snapshot_identifier, db_identifier)
        return True
    else:
        logger.info('Snapshot %s of RDS DB %s is not yet available. It\'s current status is: %s.', snapshot_identifier, db_identifier, status)
        return False


"""Returns the status of the given RDS snapshot
"""
def get_snapshot_status(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier):
    logger.info('Looking up percent progress for snapshot %s of RDS DB %s', snapshot_identifier, db_identifier)

    if db_is_aurora_cluster:
        response = rds_client.describe_db_cluster_snapshots(DBClusterSnapshotIdentifier=snapshot_identifier)
        for snapshot in response.get('DBClusterSnapshots', []):
            return snapshot.get('Status')
    else:
        response = rds_client.describe_db_snapshots(DBSnapshotIdentifier=snapshot_identifier)
        for snapshot in response.get('DBSnapshots', []):
            return snapshot.get('Status')

    return None


"""Share the given RDS snapshot with another AWS account
"""
def share_snapshot_with_account(rds_client, db_identifier, db_is_aurora_cluster, snapshot_identifier, share_with_account_id):
    logger.info('Sharing snapshot %s of RDS DB %s with AWS account %s', snapshot_identifier, db_identifier, share_with_account_id)

    if db_is_aurora_cluster:
        rds_client.modify_db_cluster_snapshot_attribute(
            DBClusterSnapshotIdentifier=snapshot_identifier,
            AttributeName='restore',
            ValuesToAdd=[share_with_account_id]
        )
    else:
        rds_client.modify_db_snapshot_attribute(
            DBSnapshotIdentifier=snapshot_identifier,
            AttributeName='restore',
            ValuesToAdd=[share_with_account_id]
        )


"""Retry this entire lambda function by triggering it asynchronously again, unless max_retries has been exceeded, in
   which case, raise an Exception
"""
def retry(lambda_client, event, retries, max_retries, sleep_between_retries_sec, db_identifier, snapshot_identifier):
    logger.info('Snapshot %s of RDS DB %s is still not ready after %d retries', snapshot_identifier, db_identifier, retries)

    retries = retries + 1
    if retries > max_retries:
        raise Exception('Max retries (%d) exceeded!', max_retries)

    logger.info('Sleeping for %d seconds and will asynchronously trigger this lambda function to try again.', sleep_between_retries_sec)
    time.sleep(sleep_between_retries_sec)

    event['retries'] = retries
    trigger_this_lambda_function(lambda_client, event)


"""Asynchronously trigger this same lambda function again
"""
def trigger_this_lambda_function(lambda_client, event):
    function_name = os.environ['AWS_LAMBDA_FUNCTION_NAME']

    logger.info('Asynchronously triggering this lambda function (%s) to retry', function_name)

    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='Event',
        Payload=json.dumps(event)
    )

    status_code = response['StatusCode']
    if status_code < 200 or status_code > 299:
        raise Exception('Got a non-200 status code when trying to invoke lambda function %s: %d', function_name, status_code)

