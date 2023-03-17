import os
import logging
import boto3
from botocore.exceptions import ClientError
import re

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Example: arn:aws:rds:us-east-1:1234567890:cluster-snapshot:foo-snapshot-2017-03-02t16-35-52
AWS_RDS_SNAPSHOT_ARN_REGEX = re.compile('arn:aws:rds:.+?:(.+?):.+?:(.+?)$')

def handler(event, context):
    """
    Main entrypoint for the lambda function. It does the following:

    1. Look for any shared snapshots of a specific RDS DB from another AWS account that have been shared with this AWS
       account and if those shared snapshots haven't already been copied into this account, copy them.
    2. Optionally report a custom metric to CloudWatch. You can add an alert on this metric to detect if a backup failed.

    All parameters for the RDS DB are passed in as environment variables.
    """

    logger.info(f'Received event {event}')

    aws_region = os.environ['AWS_REGION']

    db_identifier = os.environ['DB_IDENTIFIER']
    db_is_aurora_cluster = os.environ['DB_IS_AURORA_CLUSTER'] == 'true'
    db_account_id = os.environ['DB_ACCOUNT_ID']

    metric_namespace = os.environ.get('METRIC_NAMESPACE')
    metric_name = os.environ.get('METRIC_NAME')
    metric_unit = os.environ.get('METRIC_UNIT', 'Count')

    kms_key_id = os.environ.get('KMS_KEY_ID')

    session = boto3.session.Session(region_name=aws_region)
    rds_client = session.client('rds')
    cloudwatch_client = session.client('cloudwatch')

    all_shared_snapshots = find_all_shared_snapshots(rds_client, db_is_aurora_cluster)
    if not all_shared_snapshots:
        logger.info('Did not find any shared snapshots in this account. Nothing to do.')
        return

    target_db_snapshots = filter_to_snapshots_of_target_db(all_shared_snapshots, db_identifier, db_account_id, db_is_aurora_cluster)
    if not target_db_snapshots:
        logger.info(f'None of the shared snapshots in this account are of RDS DB {db_identifier} in account {db_account_id}. Nothing to do.')
        return

    db_snapshots_to_copy = filter_to_snapshots_not_yet_copied(rds_client, target_db_snapshots, db_is_aurora_cluster)
    if not db_snapshots_to_copy:
        logger.info(f'All of the shared snapshots of RDS DB {db_identifier} in account {db_account_id} have already been copied to this AWS account. Nothing to do.')
        return

    copy_snapshots(rds_client, db_snapshots_to_copy, db_is_aurora_cluster, kms_key_id)
    report_metric(cloudwatch_client, metric_namespace, metric_name, len(db_snapshots_to_copy), metric_unit)


def find_all_shared_snapshots(rds_client, db_is_aurora_cluster):
    """
    Find all RDS snapshots that have been shared with this AWS account. The AWS APIs do not offer any way to filter
    shared snapshots by cluster or snapshot ID, so unfortunately, we have to fetch all of them and filter them manually.
    """
    logger.info('Looking up all RDS snapshots that have been shared with this AWS account')

    snapshots = []
    marker = ''

    while True:
        if db_is_aurora_cluster:
            response = rds_client.describe_db_cluster_snapshots(
                SnapshotType='shared',
                Marker=marker,
                IncludeShared=True,
            )

            snapshots.extend(response.get('DBClusterSnapshots', []))
            marker = response.get('Marker')
        else:
            response = rds_client.describe_db_snapshots(
                SnapshotType='shared',
                Marker=marker,
                IncludeShared=True,
            )

            snapshots.extend(response.get('DBSnapshots', []))
            marker = response.get('Marker')

        if not marker:
            return snapshots


def filter_to_snapshots_not_yet_copied(rds_client, snapshots, db_is_aurora_cluster):
    """
    Filter the list of snapshots to those that have not already been copied locally.
    """
    logger.info(f'Filtering the following list of snapshots to those that have not already been copied into this AWS account: {snapshots}')
    snapshots_not_yet_copied = [s for s in snapshots if not local_copy_of_snapshot_exists(rds_client, s, db_is_aurora_cluster)]
    return snapshots_not_yet_copied


def local_copy_of_snapshot_exists(rds_client, snapshot, db_is_aurora_cluster):
    """
    Returns True if a local copy of the given shared snapshot exists in this AWS account. We use the same snapshot ID
    when making a local copy, so this is just a lookup of that snapshot ID.
    """
    snapshot_id = get_snapshot_id_from_snapshot(snapshot, db_is_aurora_cluster)
    logger.info(f'Looking up if a local copy of snapshot {snapshot_id} exists')

    try:
        if db_is_aurora_cluster:
            response = rds_client.describe_db_cluster_snapshots(
                DBClusterSnapshotIdentifier=snapshot_id,
                IncludeShared=False,
            )
            return len(response.get('DBClusterSnapshots', [])) > 0
        else:
            response = rds_client.describe_db_snapshots(
                DBSnapshotIdentifier=snapshot_id,
                IncludeShared=False,
            )
            return len(response.get('DBSnapshots', [])) > 0
    except ClientError as e:
        if e.response['Error']['Code'] in ['DBClusterSnapshotNotFoundFault', 'DBSnapshotNotFound']:
            return False
        else:
            raise e


def filter_to_snapshots_of_target_db(all_shared_snapshots, target_db_identifier, target_db_account_id, target_db_is_aurora_cluster):
    """
    Filter the list of shared snapshots to those from the specified RDS DB and AWS account.
    """
    logger.info(f'Filtering the following RDS snapshots to those that are of RDS DB {target_db_identifier} in AWS account {target_db_account_id}: {all_shared_snapshots}')

    target_snapshots = [s for s in all_shared_snapshots if is_snapshot_of_target_db(s, target_db_identifier, target_db_account_id, target_db_is_aurora_cluster)]
    return target_snapshots


def copy_snapshots(rds_client, db_snapshots_to_copy, db_is_aurora_cluster, kms_key_id):
    """
    Make local copies of the list of shared snapshots, using the same snapshot ID for the local copy.
    """
    logger.info(f'Making local copies of snapshots: {db_snapshots_to_copy}')

    for snapshot in db_snapshots_to_copy:
        copy_snapshot(rds_client, snapshot, db_is_aurora_cluster, kms_key_id)


def copy_snapshot(rds_client, snapshot, db_is_aurora_cluster, kms_key_id):
    """
    Make a local copy of the given shared snapshot, using the same snapshot ID for the local copy.
    """
    snapshot_arn = get_snapshot_arn_from_snapshot(snapshot, db_is_aurora_cluster)
    snapshot_id = get_snapshot_id_from_snapshot(snapshot, db_is_aurora_cluster)

    logger.info(f'Making a local copy of snapshot {snapshot_arn} to {snapshot_id}')

    if db_is_aurora_cluster:
        rds_client.copy_db_cluster_snapshot(
            SourceDBClusterSnapshotIdentifier=snapshot_arn,
            TargetDBClusterSnapshotIdentifier=snapshot_id,
            KmsKeyId=kms_key_id,
        )
    else:
        rds_client.copy_db_snapshot(
            SourceDBSnapshotIdentifier=snapshot_arn,
            TargetDBSnapshotIdentifier=snapshot_id,
            KmsKeyId=kms_key_id,
        )


def is_snapshot_of_target_db(snapshot, target_db_identifier, target_db_account_id, target_db_is_aurora_cluster):
    """
    Returns true if the given RDS snapshot is a snapshot of the given DB in the given AWS account
    """
    snapshot_db_identifier = get_db_identifier_from_snapshot(snapshot, target_db_is_aurora_cluster)
    snapshot_account_id = get_account_id_from_snapshot(snapshot, target_db_is_aurora_cluster)
    return snapshot_db_identifier == target_db_identifier and snapshot_account_id == target_db_account_id


def get_db_identifier_from_snapshot(snapshot, db_is_aurora_cluster):
    """
    Return the DB identifier from the given shared snapshot
    """
    return snapshot['DBClusterIdentifier'] if db_is_aurora_cluster else snapshot['DBInstanceIdentifier']


def get_account_id_from_snapshot(snapshot, db_is_aurora_cluster):
    """
    Return the account ID from the given shared snapshot
    """
    arn = parse_rds_arn(snapshot, db_is_aurora_cluster)
    return arn['account_id']


def get_snapshot_id_from_snapshot(snapshot, db_is_aurora_cluster):
    """
    Return the snapshot ID from the given shared snapshot
    """
    arn = parse_rds_arn(snapshot, db_is_aurora_cluster)
    return arn['snapshot_id']


def get_snapshot_arn_from_snapshot(snapshot, db_is_aurora_cluster):
    """
    Return the ARN of the given shared snapshot
    """
    return snapshot['DBClusterSnapshotArn'] if db_is_aurora_cluster else snapshot['DBSnapshotArn']


def parse_rds_arn(snapshot, db_is_aurora_cluster):
    """
    Parse the ARN of the given shared snapshot and return a dictionary that contains the snapshot's AWS account ID and
    the snapshot ID.

    Example: {'account_id': 'XXX', 'snapshot_id': 'YYY'}
    """
    snapshot_arn = get_snapshot_arn_from_snapshot(snapshot, db_is_aurora_cluster)
    matches = AWS_RDS_SNAPSHOT_ARN_REGEX.match(snapshot_arn)
    if len(matches.groups()) != 2:
        raise Exception(f'Unable to parse RDS ARN: {snapshot_arn}')

    return {'account_id': matches.group(1), 'snapshot_id': matches.group(2)}


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
