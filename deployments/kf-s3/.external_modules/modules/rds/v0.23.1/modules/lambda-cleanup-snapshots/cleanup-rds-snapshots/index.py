import os
import logging
import boto3

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Main entrypoint for the lambda function. It does the following:

    1. Find all snapshots for a given RDS DB and if there are more than a pre-configured number, delete the oldest ones.

    All parameters for the DB and max allowed number of snapshots are configured via environment variables.
    """
    logger.info(f'Received event {event}')

    aws_region = os.environ['AWS_REGION']

    db_identifier = os.environ['DB_IDENTIFIER']
    db_is_aurora_cluster = os.environ['DB_IS_AURORA_CLUSTER'] == 'true'
    max_snapshots = int(os.environ['MAX_SNAPSHOTS'])
    allow_delete_all = os.environ.get('ALLOW_DELETE_ALL')
    snapshot_namespace = os.environ.get('SNAPSHOT_NAMESPACE')

    if max_snapshots < 0:
        raise Exception('MAX_SNAPSHOTS must be a non negative number')

    if max_snapshots == 0 and not allow_delete_all:
        raise Exception('MAX_SNAPSHOTS is set to zero. This would delete ALL of your snapshots! Since ALLOW_DELETE_ALL is not set, exiting.')

    session = boto3.session.Session(region_name=aws_region)
    rds_client = session.client('rds')

    all_snapshots = find_snapshots_of_db(rds_client, db_identifier, db_is_aurora_cluster, snapshot_namespace)
    available_snapshots = [snapshot for snapshot in all_snapshots if snapshot.get('Status') == 'available']

    num_available_snapshots = len(available_snapshots)
    if num_available_snapshots > max_snapshots:
        snapshots_to_delete = select_oldest_snapshots(available_snapshots, max_snapshots, db_identifier)
        delete_snapshots(rds_client, snapshots_to_delete, db_identifier, db_is_aurora_cluster)
    else:
        logger.info(f'Found {num_available_snapshots} snapshots of RDS DB {db_identifier}, which is less than the max allowed of {max_snapshots}. Nothing to do.')


def find_snapshots_of_db(rds_client, db_identifier, db_is_aurora_cluster, snapshot_namespace):
    """
    Find all the local snapshots of the given RDS DB
    Filters snapshots by manual type:
       (An error occurred (InvalidDBClusterSnapshotStateFault) when calling the DeleteDBClusterSnapshot operation: Only manual snapshots may be deleted)
    """
    logger.info(f'Looking up snapshots of RDS DB {db_identifier}')

    snapshots = []
    marker = ''

    while True:
        if db_is_aurora_cluster:
            response = rds_client.describe_db_cluster_snapshots(
                DBClusterIdentifier=db_identifier,
                Marker=marker,
                SnapshotType='manual',
            )

            snapshots.extend(response.get('DBClusterSnapshots', []))
            marker = response.get('Marker')
        else:
            response = rds_client.describe_db_snapshots(
                DBInstanceIdentifier=db_identifier,
                Marker=marker,
                SnapshotType='manual',
            )

            snapshots.extend(response.get('DBSnapshots', []))
            marker = response.get('Marker')

        if not marker:
            if snapshot_namespace:
                identifier_key = 'DBClusterSnapshotIdentifier' if db_is_aurora_cluster else 'DBSnapshotIdentifier'
                suffix_filter = lambda snapshot : snapshot[identifier_key].endswith(f'-{snapshot_namespace}')
                return filter(suffix_filter, snapshots)
            else:
                return snapshots


def select_oldest_snapshots(all_snapshots, max_snapshots, db_identifier):
    """
    Return the oldest N snapshots from the given list of snapshots, where N = length of the list of snapshots minus
    max snapshots.
    """
    num_snapshots_to_delete = len(all_snapshots) - max_snapshots
    logger.info(f'There are more than {max_snapshots} snapshots of RDS DB {db_identifier}. Selecting the oldest {num_snapshots_to_delete} to delete.')

    all_snapshots_sorted = sorted(all_snapshots, key=lambda snapshot: snapshot['SnapshotCreateTime'])
    return all_snapshots_sorted[:num_snapshots_to_delete]


def delete_snapshots(rds_client, snapshots_to_delete, db_identifier, db_is_aurora_cluster):
    """
    Delete the given list of RDS snapshots
    """
    logger.info(f'Deleting the following snapshots from RDS DB {db_identifier}: {snapshots_to_delete}')
    for snapshot in snapshots_to_delete:
        delete_snapshot(rds_client, snapshot, db_identifier, db_is_aurora_cluster)


def delete_snapshot(rds_client, snapshot, db_identifier, db_is_aurora_cluster):
    """
    Delete the given RDS snapshot
    """
    snapshot_id = snapshot['DBClusterSnapshotIdentifier'] if db_is_aurora_cluster else snapshot['DBSnapshotIdentifier']
    logger.info(f'Deleting snapshot {snapshot_id} for RDS DB {db_identifier}')
    if db_is_aurora_cluster:
        rds_client.delete_db_cluster_snapshot(DBClusterSnapshotIdentifier=snapshot_id)
    else:
        rds_client.delete_db_snapshot(DBSnapshotIdentifier=snapshot_id)
