output "backup_service_role_arn" {
  description = "The ARN of the IAM service role used by Backup plans"
  value       = aws_iam_role.backup_service_role.arn
}

output "backup_plan_arns" {
  description = "A list of the ARNs for any Backup plans configured"
  value       = [for plan_name, plan in aws_backup_plan.plan : plan.arn]
}

output "backup_plan_ids" {
  description = "A list of IDs for any Backup plans configured"
  value       = [for plan_name, plan in aws_backup_plan.plan : plan.id]
}

output "backup_plan_tags_all" {
  description = "A list of maps of tags assigned to the plans, including those inherited from the provider default_tags block"
  value       = [for plan_name, plan in aws_backup_plan.plan : plan.tags_all]
}

output "backup_selection_ids" {
  description = "A list of IDs for any Backup selections configured"
  value       = [for selection_name, selection in aws_backup_selection.selection : selection.id]
}
