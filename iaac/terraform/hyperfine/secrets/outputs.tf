
output "rds_secret_name" {
  value = aws_secretsmanager_secret.rds-secret.name
}

output "s3_secret_name" {
  value = aws_secretsmanager_secret.s3-secret.name
}

output "kms_key_ids" {
  value = concat([aws_kms_key.kms.key_id], var.additional_kms_key_ids)
}

output "rds_host" {
  value = var.rds_host
}

output "s3_bucket_name" {
  value = var.s3_bucket_name
}

output "s3_region" {
  value = var.s3_region
}