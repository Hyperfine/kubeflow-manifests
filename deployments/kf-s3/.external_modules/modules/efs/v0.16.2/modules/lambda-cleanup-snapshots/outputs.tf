output "lambda_function_arn" {
  value = module.delete_snapshots.function_arn
}

output "lambda_iam_role_id" {
  value = module.delete_snapshots.iam_role_id
}
