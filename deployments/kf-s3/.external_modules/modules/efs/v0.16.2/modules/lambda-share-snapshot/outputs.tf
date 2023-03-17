output "lambda_function_arn" {
  value = module.share_snapshot.function_arn
}

output "lambda_iam_role_id" {
  value = module.share_snapshot.iam_role_id
}
