output "lambda_function_arn" {
  value = module.create_snapshot.function_arn
}

output "lambda_iam_role_id" {
  value = module.create_snapshot.iam_role_id
}
