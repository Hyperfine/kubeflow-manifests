output "endpoint" {
  value       = aws_redshift_cluster.cluster.endpoint
  description = "The cluter's connection endpoint"
}

output "dns_name" {
  value       = aws_redshift_cluster.cluster.dns_name
  description = "The DNS name of the cluster"
}

output "id" {
  value       = aws_redshift_cluster.cluster.id
  description = "The Redshift Cluster ID"
}

output "arn" {
  value       = aws_redshift_cluster.cluster.arn
  description = " Amazon Resource Name (ARN) of cluster"
}

output "port" {
  value       = var.port
  description = "The Port the cluster responds on"
}

output "security_group_id" {
  value       = aws_security_group.db.id
  description = "The ID of the Security Group that controls access to the cluster"
}

output "name" {
  value       = var.name
  description = "The name of the Redshift cluster"
}

output "db_name" {
  value       = aws_redshift_cluster.cluster.database_name
  description = "The name of the Database in the cluster"
}

output "parameter_group_name" {
  value       = local.parameter_group_name
  description = "The name of the parameter group associated with this cluster"
}
