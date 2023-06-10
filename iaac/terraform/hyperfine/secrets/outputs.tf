
output "rds_secret_name" {
  value = aws_secretsmanager_secret.rds-secret.name
}

output "s3_secret_name" {
  value = aws_secretsmanager_secret.s3-secret.name
}

output "kms_key_ids" {
  value = concat([aws_kms_key.kms.key_id], var.additional_kms_key_ids)
}
