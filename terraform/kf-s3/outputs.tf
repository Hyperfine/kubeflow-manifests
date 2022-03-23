
output "bucket" {
  value = aws_s3_bucket.source.bucket
}


output "secret_id" {
  value = aws_secretsmanager_secret_version.s3-secret-version.arn
}