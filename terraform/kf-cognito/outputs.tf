output "cert_arn" {
  value = module.acm_kubeflow.acm_certificate_arn
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "pool_arn" {
  value = aws_cognito_user_pool.pool.arn
}

output "cognito_domain" {
  value = local.cognito_url
}