output "mysql_db_name" {
  value = module.mysql_example.name
}

output "mysql_primary_endpoint" {
  value = module.mysql_example.primary_endpoint
}

output "mysql_parameter_group_name" {
  value = module.mysql_example.parameter_group_name
}

# These will only show up if you set num_read_replicas > 0
output "mysql_read_replica_endpoints" {
  value = module.mysql_example.read_replica_endpoints
}

output "mysql_port" {
  value = module.mysql_example.port
}
