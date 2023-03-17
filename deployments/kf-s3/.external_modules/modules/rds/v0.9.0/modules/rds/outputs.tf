output "primary_endpoint" {
  value = element(
    concat(
      aws_db_instance.primary_with_encryption.*.endpoint,
      aws_db_instance.primary_without_encryption.*.endpoint,
    ),
    0,
  )
}

output "read_replica_endpoints" {
  value = concat(
    aws_db_instance.replicas_with_encryption.*.endpoint,
    aws_db_instance.replicas_without_encryption.*.endpoint,
  )
}

output "primary_id" {
  value = element(
    concat(
      aws_db_instance.primary_with_encryption.*.id,
      aws_db_instance.primary_without_encryption.*.id,
    ),
    0,
  )
}

output "read_replica_ids" {
  value = concat(
    aws_db_instance.replicas_with_encryption.*.id,
    aws_db_instance.replicas_without_encryption.*.id,
  )
}

output "primary_arn" {
  value = element(
    concat(
      aws_db_instance.primary_with_encryption.*.arn,
      aws_db_instance.primary_without_encryption.*.arn,
    ),
    0,
  )
}

output "read_replica_arns" {
  value = concat(
    aws_db_instance.replicas_with_encryption.*.arn,
    aws_db_instance.replicas_without_encryption.*.arn,
  )
}

output "port" {
  value = var.port
}

output "security_group_id" {
  value = element(concat(aws_security_group.db.*.id, [""]), 0)
}

output "db_name" {
  value = element(
    concat(
      aws_db_instance.primary_with_encryption.*.name,
      aws_db_instance.primary_without_encryption.*.name,
    ),
    0,
  )
}

output "parameter_group_name" {
  value = local.parameter_group_name
}
