# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AWS BACKUP VAULTS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.0, < 4.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AWS BACKUP VAULTS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_backup_vault" "vault" {
  for_each    = local.vaults
  name        = each.key
  kms_key_arn = each.value.kms_key_arn
}
# ---------------------------------------------------------------------------------------------------------------------
# CREATE AWS BACKUP VAULT POLICY
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "vault_policy" {
  for_each = local.vaults

  statement {
    sid = "VaultPolicy"

    actions = [
      "backup:DescribeBackupVault",
      "backup:DeleteBackupVault",
      "backup:DeleteBackupVaultLockConfiguration",
      "backup:PutBackupVaultLockConfiguration",
      "backup:PutBackupVaultAccessPolicy",
      "backup:DeleteBackupVaultAccessPolicy",
      "backup:GetBackupVaultAccessPolicy",
      "backup:StartBackupJob",
      "backup:GetBackupVaultNotifications",
      "backup:PutBackupVaultNotifications",
    ]

    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      "*"
    ]
  }
}

resource "aws_backup_vault_policy" "vault_policy" {
  for_each          = local.vaults_with_policies_attached
  backup_vault_name = each.key
  policy            = data.aws_iam_policy_document.vault_policy[each.key].json
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AWS BACKUP VAULT LOCK CONFIGURATIONS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_backup_vault_lock_configuration" "lock" {
  for_each = {
    for vault_name, conf in local.vaults :
    vault_name => conf if conf.locked
  }
  backup_vault_name = each.key
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AWS BACKUP VAULT NOTIFICATIONS
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "vault_topic_policy" {
  for_each = local.vaults_with_notifications

  statement {
    sid = "BackupPublishEvents"

    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.vault_topic[each.key].arn,
    ]
  }
}

resource "aws_sns_topic" "vault_topic" {
  for_each = local.vaults_with_notifications
  name     = "${each.key}-events"
}

resource "aws_sns_topic_policy" "vault_topic_policy" {
  for_each = local.vaults_with_notifications
  arn      = aws_sns_topic.vault_topic[each.key].arn
  policy   = data.aws_iam_policy_document.vault_topic_policy[each.key].json
}

resource "aws_backup_vault_notifications" "vault_notifications" {
  for_each            = local.vaults_with_notifications
  backup_vault_name   = each.key
  sns_topic_arn       = aws_sns_topic.vault_topic[each.key].arn
  backup_vault_events = each.value.events_to_listen_for
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  vaults = { for vault_name, conf in var.vaults :
    vault_name => {
      kms_key_arn          = lookup(conf, "kms_key_arn", null),
      locked               = lookup(conf, "locked", false),
      changeable_for_days  = lookup(conf, "changeable_for_days", var.default_changeable_for_days),
      max_retention_days   = lookup(conf, "max_retention_days", var.default_max_retention_days),
      min_retention_days   = lookup(conf, "min_rention_days", var.default_min_retention_days)
      enable_notifications = lookup(conf, "enable_notifications", false),
      events_to_listen_for = lookup(conf, "events_to_listen_for", local.all_backup_events)
      attach_policy        = lookup(conf, "attach_policy", false)
    }
  }

  vaults_with_notifications = { for vault_name, conf in local.vaults : vault_name => conf if conf.enable_notifications }

  vaults_with_policies_attached = { for vault_name, conf in local.vaults : vault_name => conf if conf.attach_policy }

  # If operator does not pass in a specific list of AWS Backup events to listen for, default to listening for all events
  all_backup_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "COPY_JOB_STARTED",
    "COPY_JOB_SUCCESSFUL",
    "COPY_JOB_FAILED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED",
    "RECOVERY_POINT_MODIFIED"
  ]

}
