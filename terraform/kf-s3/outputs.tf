
output "bucket" {
  value = module.bucket.primary_bucket_name
}

output "secret_id" {
  value = aws_secretsmanager_secret_version.s3-secret-version.arn
}