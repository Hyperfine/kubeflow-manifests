output "cert_arn" {
  value = local.cert_arn
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

output "kubeflow_zone_id" {
  value = aws_route53_zone.kubeflow_zone.zone_id
}

output "kubeflow_name" {
  value = aws_route53_zone.kubeflow_zone.name
}
