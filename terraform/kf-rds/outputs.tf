output "db_identifier" {
  value = module.rds.primary_id
}

output "rds_secret_version_arn" {
  value = aws_secretsmanager_secret_version.rds_version.arn
}

output "rds_info" {
  value = local.rds_info
  sensitive = true
}