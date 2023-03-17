output "cluster_endpoint" {
  value = aws_rds_cluster.cluster.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.cluster.reader_endpoint
}

output "instance_endpoints" {
  value = aws_rds_cluster_instance.cluster_instances.*.endpoint
}

# The DB Cluster ID or name of the cluster, e.g. "my-aurora-cluster"
output "cluster_id" {
  value = aws_rds_cluster.cluster.id
}

# The unique resource ID assigned to the cluster e.g. "cluster-POBCBQUFQC56EBAAWXGFJ77GRU"
# This is useful for allowing database authentication via IAM
output "cluster_resource_id" {
  value = aws_rds_cluster.cluster.cluster_resource_id
}

# Terraform does not provide an output for the cluster ARN, so we have to build it ourselves
output "cluster_arn" {
  value = "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster:${aws_rds_cluster.cluster.id}"
}

output "instance_ids" {
  value = aws_rds_cluster_instance.cluster_instances.*.id
}

output "port" {
  value = var.port
}

output "security_group_id" {
  value = aws_security_group.cluster.id
}

output "db_name" {
  value = var.db_name
}

output "cluster_instances_maintenance_window" {
  value = data.template_file.cluster_instances_maintenance_window[*].rendered
}
