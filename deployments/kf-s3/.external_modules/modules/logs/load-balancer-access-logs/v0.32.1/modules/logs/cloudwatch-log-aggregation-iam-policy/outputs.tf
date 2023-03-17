output "cloudwatch_log_aggregation_policy_name" {
  value = var.create_resources ? aws_iam_policy.cloudwatch_log_aggregation[0].name : null
}

output "cloudwatch_log_aggregation_policy_id" {
  value = var.create_resources ? aws_iam_policy.cloudwatch_log_aggregation[0].id : null
}

output "cloudwatch_log_aggregation_policy_arn" {
  value = var.create_resources ? aws_iam_policy.cloudwatch_log_aggregation[0].arn : null
}

output "cloudwatch_logs_permissions_json" {
  value = data.aws_iam_policy_document.cloudwatch_logs_permissions.json
}