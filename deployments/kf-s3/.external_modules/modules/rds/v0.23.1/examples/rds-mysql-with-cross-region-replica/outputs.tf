output "mysql_primary_name" {
  value = module.mysql_primary.name
}

output "mysql_primary_endpoint" {
  value = module.mysql_primary.primary_endpoint
}

output "mysql_primary_port" {
  value = module.mysql_primary.port
}

output "mysql_replica_name" {
  value = module.mysql_replica.name
}

output "mysql_replica_endpoint" {
  value = module.mysql_replica.primary_endpoint
}

output "mysql_replica_port" {
  value = module.mysql_replica.port
}
