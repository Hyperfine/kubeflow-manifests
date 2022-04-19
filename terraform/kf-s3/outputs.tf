
output "bucket" {
  value = module.s3.outputs.name
}

output "secret_id" {
  value = aws_secretsmanager_secret_version.s3-secret-version.arn
}