output "cluster_endpoint" {
  value = element(
    concat(
      aws_rds_cluster.cluster_with_encryption_serverless.*.endpoint,
      aws_rds_cluster.cluster_with_encryption_provisioned.*.endpoint,
      aws_rds_cluster.cluster_without_encryption.*.endpoint,
    ),
    0,
  )
}

output "reader_endpoint" {
  value = element(
    concat(
      aws_rds_cluster.cluster_with_encryption_serverless.*.reader_endpoint,
      aws_rds_cluster.cluster_with_encryption_provisioned.*.reader_endpoint,
      aws_rds_cluster.cluster_without_encryption.*.reader_endpoint,
    ),
    0,
  )
}

output "instance_endpoints" {
  value = aws_rds_cluster_instance.cluster_instances.*.endpoint
}

output "cluster_id" {
  value = element(
    concat(
      aws_rds_cluster.cluster_with_encryption_serverless.*.id,
      aws_rds_cluster.cluster_with_encryption_provisioned.*.id,
      aws_rds_cluster.cluster_without_encryption.*.id,
    ),
    0,
  )
}

# Terraform does not provide an output for the cluster ARN, so we have to build it ourselves
output "cluster_arn" {
  value = "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster:${element(
    concat(
      aws_rds_cluster.cluster_with_encryption_serverless.*.cluster_identifier,
      aws_rds_cluster.cluster_with_encryption_provisioned.*.cluster_identifier,
      aws_rds_cluster.cluster_without_encryption.*.cluster_identifier,
    ),
    0,
  )}"
}

output "instance_ids" {
  value = aws_rds_cluster_instance.cluster_instances.*.id
}

output "port" {
  value = element(
    concat(
      aws_rds_cluster.cluster_with_encryption_serverless.*.port,
      aws_rds_cluster.cluster_with_encryption_provisioned.*.port,
      aws_rds_cluster.cluster_without_encryption.*.port,
    ),
    0,
  )
}

output "security_group_id" {
  value = element(concat(aws_security_group.cluster.*.id, [""]), 0)
}

output "db_name" {
  value = var.db_name
}
