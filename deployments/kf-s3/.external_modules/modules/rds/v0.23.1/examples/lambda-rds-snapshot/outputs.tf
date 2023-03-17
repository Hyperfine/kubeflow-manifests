output "mysql_primary_id" {
  value = module.mysql.primary_id
}

output "mysql_primary_arn" {
  value = module.mysql.primary_arn
}

output "mysql_primary_endpoint" {
  value = module.mysql.primary_endpoint
}

# These will only show up if you set num_read_replicas > 0
output "mysql_read_replica_endpoints" {
  value = [module.mysql.read_replica_endpoints]
}

output "mysql_port" {
  value = module.mysql.port
}

output "mysql_snapshot_lambda_function_arn" {
  value = module.mysql_create_snapshot.lambda_function_arn
}

output "aurora_cluster_id" {
  value = module.aurora.cluster_id
}

output "aurora_cluster_arn" {
  value = module.aurora.cluster_arn
}

output "aurora_cluster_endpoint" {
  value = module.aurora.cluster_endpoint
}

output "aurora_instance_endpoints" {
  value = [module.aurora.instance_endpoints]
}

output "aurora_port" {
  value = module.aurora.port
}

output "mysql_create_snapshot_lambda_arn" {
  value = module.mysql_create_snapshot.lambda_function_arn
}

output "aurora_create_snapshot_lambda_arn" {
  value = module.aurora_create_snapshot.lambda_function_arn
}

output "mysql_share_snapshot_lambda_arn" {
  value = module.mysql_share_snapshot.lambda_function_arn
}

output "aurora_share_snapshot_lambda_arn" {
  value = module.aurora_share_snapshot.lambda_function_arn
}

output "mysql_copy_shared_snapshot_lambda_arn" {
  value = module.mysql_copy_shared_snapshot.lambda_function_arn
}

output "aurora_copy_shared_snapshot_lambda_arn" {
  value = module.aurora_copy_shared_snapshot.lambda_function_arn
}

output "mysql_cleanup_snapshots_lambda_arn" {
  value = module.mysql_cleanup_snapshots.lambda_function_arn
}

output "aurora_cleanup_snapshots_lambda_arn" {
  value = module.aurora_cleanup_snapshots.lambda_function_arn
}
