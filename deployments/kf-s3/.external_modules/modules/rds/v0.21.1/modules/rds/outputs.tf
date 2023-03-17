output "primary_endpoint" {
  value = local.rds_instance.endpoint
}

output "primary_address" {
  value = local.rds_instance.address
}

output "primary_id" {
  value = local.rds_instance.id
}

output "primary_arn" {
  value = local.rds_instance.arn
}

output "read_replica_endpoints" {
  value = aws_db_instance.replicas[*].endpoint
}

output "read_replica_addresses" {
  value = aws_db_instance.replicas[*].address
}

output "read_replica_ids" {
  value = aws_db_instance.replicas[*].id
}

output "read_replica_arns" {
  value = aws_db_instance.replicas[*].arn
}

output "port" {
  value = var.port
}

output "security_group_id" {
  value = aws_security_group.db.id
}

output "name" {
  value = var.name
}

output "db_name" {
  value = local.rds_instance.name
}

output "parameter_group_name" {
  value = local.parameter_group_name
}
