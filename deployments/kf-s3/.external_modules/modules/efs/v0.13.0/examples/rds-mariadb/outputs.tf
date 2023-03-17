output "mariadb_primary_endpoint" {
  value = module.mariadb_example.primary_endpoint
}

output "mariadb_parameter_group_name" {
  value = module.mariadb_example.parameter_group_name
}

# These will only show up if you set num_read_replicas > 0
output "mariadb_read_replica_endpoints" {
  value = module.mariadb_example.read_replica_endpoints
}

output "mariadb_port" {
  value = module.mariadb_example.port
}
