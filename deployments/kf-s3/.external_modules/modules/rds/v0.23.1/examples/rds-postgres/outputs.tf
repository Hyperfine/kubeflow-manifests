output "postgres_db_name" {
  value = module.postgres_example.name
}

output "postgres_parameter_group_name" {
  value = module.postgres_example.parameter_group_name
}

output "postgres_primary_endpoint" {
  value = module.postgres_example.primary_endpoint
}

# These will only show up if you set num_read_replicas > 0
output "postgres_read_replica_endpoints" {
  value = module.postgres_example.read_replica_endpoints
}

output "postgres_port" {
  value = module.postgres_example.port
}
