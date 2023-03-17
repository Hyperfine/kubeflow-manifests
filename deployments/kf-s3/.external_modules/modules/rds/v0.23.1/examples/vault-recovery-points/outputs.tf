output "iam_role_arn" {
  description = "The ARN of the IAM Backup service role created for use by the backup plan"
  value       = module.backup_plan.backup_service_role_arn
}

output "ec2_instance_arn" {
  description = "The ARN of the EC2 instance deployed as a target for test backup jobs"
  # Construct the ARN for the EC2 instance via interpolation
  value = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.web.id}"
}

output "vault_names" {
  value = module.backup_vault.vault_names
}

output "vault_arns" {
  value = module.backup_vault.vault_arns
}
