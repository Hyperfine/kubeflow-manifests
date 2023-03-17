output "lambda_function_arn" {
  value = module.copy_shared_snapshot.function_arn
}

output "lambda_iam_role_id" {
  value = module.copy_shared_snapshot.iam_role_id
}
