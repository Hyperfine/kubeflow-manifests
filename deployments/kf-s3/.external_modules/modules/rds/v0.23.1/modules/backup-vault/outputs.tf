output "vault_arns" {
  description = "The ARNs of the Backup vaults"
  value = {
    for vault_name, conf in aws_backup_vault.vault : vault_name => aws_backup_vault.vault[vault_name].arn
  }
}

output "vault_names" {
  description = "The names of the Backup vaults"
  value = {
    for vault_name, conf in aws_backup_vault.vault : vault_name => aws_backup_vault.vault[vault_name].name
  }
}

output "vault_recovery_points" {
  description = "The count of recovery points stored in each vault"
  value = {
    for vault_name, conf in aws_backup_vault.vault : vault_name => aws_backup_vault.vault[vault_name].recovery_points
  }
}

output "vault_tags_all" {
  description = "A map of tags assigned to the vault resources, including those inherited from the provider's default_tags block"
  value = {
    for vault_name, conf in aws_backup_vault.vault : vault_name => lookup(aws_backup_vault.vault[vault_name], "vault_tags_all", {})
  }
}

output "vault_sns_topic_arns" {
  description = "A list of the ARNs for any SNS topics that may have been created to support Backup vault notifications"
  value = {
    for sns_topic, conf in aws_sns_topic.vault_topic : sns_topic => aws_sns_topic.vault_topic[sns_topic].arn
  }
}

output "count_of_vault_locks" {
  description = "A sanity check count of the number of aws_backup_vault_lock_configurations that were applied to vaults"
  value       = [length(aws_backup_vault_lock_configuration.lock)]
}

output "count_of_vault_notifications" {
  description = "A sanity check count of the number of SNS topics that were created to support Backup vault notifications"
  value       = [length(aws_backup_vault_notifications.vault_notifications)]
}
