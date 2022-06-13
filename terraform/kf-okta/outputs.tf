output "okta-secret-name" {
  value = aws_secretsmanager_secret.okta-secret.name
}

output "kms-key-id" {
  value = var.kms_key_id
}

output "okta_id" {
  value = okta_app_oauth.kf.id
}
