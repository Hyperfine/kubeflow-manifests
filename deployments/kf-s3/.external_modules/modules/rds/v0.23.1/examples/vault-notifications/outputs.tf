output "vault_arns" {
  value = module.backup_vault.vault_arns
}

output "vault_names" {
  value = module.backup_vault.vault_names
}

output "vault_recovery_points" {
  value = module.backup_vault.vault_recovery_points
}

output "vault_tags_all" {
  value = module.backup_vault.vault_tags_all
}

output "vault_sns_topic_arns" {
  value = module.backup_vault.vault_sns_topic_arns
}
