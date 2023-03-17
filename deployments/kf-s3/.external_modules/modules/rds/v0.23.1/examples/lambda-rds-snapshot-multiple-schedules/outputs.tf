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

output "create_hourly_snapshot_lambda_arn" {
  value = module.create_hourly_snapshot.lambda_function_arn
}

output "create_weekly_snapshot_lambda_arn" {
  value = module.create_weekly_snapshot.lambda_function_arn
}

output "cleanup_hourly_snapshots_lambda_arn" {
  value = module.cleanup_hourly_snapshots.lambda_function_arn
}

output "cleanup_weekly_snapshots_lambda_arn" {
  value = module.cleanup_weekly_snapshots.lambda_function_arn
}
