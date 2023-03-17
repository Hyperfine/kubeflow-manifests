output "cloudwatch_metrics_policy_name" {
  value = var.create_resources ? aws_iam_policy.cloudwatch_metrics_read_write[0].name : null
}

output "cloudwatch_metrics_policy_id" {
  value = var.create_resources ? aws_iam_policy.cloudwatch_metrics_read_write[0].id : null
}

output "cloudwatch_metrics_policy_arn" {
  value = var.create_resources ? aws_iam_policy.cloudwatch_metrics_read_write[0].arn : null
}

output "cloudwatch_metrics_read_write_permissions_json" {
  value = data.aws_iam_policy_document.cloudwatch_metrics_read_write_permissions.json
}