import os
import logging
import boto3

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

"""Main entrypoint for the lambda function. It does the following:

   1. Find all snapshots for a given RDS DB and if there are more than a pre-configured number, delete the oldest ones.

   All parameters for the DB and max allowed number of snapshots are configured via environment variables.
"""
def handler(event, context):
    logger.info('Received event %s', event)

    aws_region = os.environ['AWS_REGION']

    db_identifier = os.environ['DB_IDENTIFIER']
    db_is_aurora_cluster = os.environ['DB_IS_AURORA_CLUSTER'] == "true"
    max_snapshots = int(os.environ['MAX_SNAPSHOTS'])
    allow_delete_all = os.environ.get('ALLOW_DELETE_ALL')

    if max_snapshots < 0:
        raise Exception('MAX_SNAPSHOTS must be a non negative number')

    if max_snapshots == 0 and not allow_delete_all:
        raise Exception('MAX_SNAPSHOTS is set to zero. This would delete ALL of your snapshots! Since ALLOW_DELETE_ALL is not set, exiting.')

    session = boto3.session.Session(region_name=aws_region)
    rds_client = session.client('rds')

    all_snapshots = find_snapshots_of_db(rds_client, db_identifier, db_is_aurora_cluster)
    available_snapshots = [snapshot for snapshot in all_snapshots if snapshot.get('Status') == 'available']

    if len(available_snapshots) > max_snapshots:
        snapshots_to_delete = select_oldest_snapshots(available_snapshots, max_snapshots, db_identifier)
        delete_snapshots(rds_client, snapshots_to_delete, db_identifier, db_is_aurora_cluster)
    else:
        logger.info('Found %d snapshots of RDS DB %s, which is less than the max allowed of %d. Nothing to do.', len(available_snapshots), db_identifier, max_snapshots)


"""Find all the local snapshots of the given RDS DB
   Filters snapshots by manual type:
   (An error occurred (InvalidDBClusterSnapshotStateFault) when calling the DeleteDBClusterSnapshot operation: Only manual snapshots may be deleted)
"""
def find_snapshots_of_db(rds_client, db_identifier, db_is_aurora_cluster):
    logger.info('Looking up snapshots of RDS DB %s', db_identifier)

    snapshots = []
    marker = ''

    while True:
        if db_is_aurora_cluster:
            response = rds_client.describe_db_cluster_snapshots(
                DBClusterIdentifier=db_identifier,
                Marker=marker,
                SnapshotType='manual'
            )

            snapshots.extend(response.get('DBClusterSnapshots', []))
            marker = response.get('Marker')
        else:
            response = rds_client.describe_db_snapshots(
                DBInstanceIdentifier=db_identifier,
                Marker=marker,
                SnapshotType='manual'
            )

            snapshots.extend(response.get('DBSnapshots', []))
            marker = response.get('Marker')

        if not marker:
            return snapshots


"""Return the oldest N snapshots from the given list of snapshots, where N = length of the list of snapshots minus
   max snapshots.
"""
def select_oldest_snapshots(all_snapshots, max_snapshots, db_identifier):
    num_snapshots_to_delete = len(all_snapshots) - max_snapshots
    logger.info('There are more than %d snapshots of RDS DB %s. Selecting the oldest %d to delete.', max_snapshots, db_identifier, num_snapshots_to_delete)

    all_snapshots_sorted = sorted(all_snapshots, key=lambda snapshot: snapshot['SnapshotCreateTime'])
    return all_snapshots_sorted[:num_snapshots_to_delete]


"""Delete the given list of RDS snapshots
"""
def delete_snapshots(rds_client, snapshots_to_delete, db_identifier, db_is_aurora_cluster):
    logger.info('Deleting the following snapshots from RDS DB %s: %s', db_identifier, snapshots_to_delete)
    for snapshot in snapshots_to_delete:
        delete_snapshot(rds_client, snapshot, db_identifier, db_is_aurora_cluster)


"""Delete the given RDS snapshot
"""
def delete_snapshot(rds_client, snapshot, db_identifier, db_is_aurora_cluster):
    snapshot_id = snapshot['DBClusterSnapshotIdentifier'] if db_is_aurora_cluster else snapshot['DBSnapshotIdentifier']
    logger.info('Deleting snapshot %s for RDS DB %s', snapshot_id, db_identifier)
    if db_is_aurora_cluster:
        rds_client.delete_db_cluster_snapshot(DBClusterSnapshotIdentifier=snapshot_id)
    else:
        rds_client.delete_db_snapshot(DBSnapshotIdentifier=snapshot_id)