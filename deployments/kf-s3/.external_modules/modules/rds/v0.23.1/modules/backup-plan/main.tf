# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AWS BACKUP PLANS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.0, < 4.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE BACKUP SERVICE ROLE
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "backup_admin_assume_role_policy" {
  statement {
    sid     = "BackupAdminAssumeRolePolicy"
    actions = ["sts:AssumeRole"]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup_service_role" {
  # The backup_service_role_name defaults to backup-service-role if not provided
  name               = var.backup_service_role_name
  assume_role_policy = data.aws_iam_policy_document.backup_admin_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "service_role_for_backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_service_role.name
}

resource "aws_iam_role_policy_attachment" "service_role_for_restores" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.backup_service_role.name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE BACKUP PLANS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_backup_plan" "plan" {
  for_each = local.plans
  name     = each.key

  rule {
    rule_name         = each.value.rule.rule_name
    target_vault_name = each.value.rule.target_vault_name
    schedule          = each.value.rule.schedule

    dynamic "lifecycle" {
      for_each = each.value.rule.lifecycle[*]
      content {
        cold_storage_after = lifecycle.value.cold_storage_after
        delete_after       = lifecycle.value.delete_after
      }
    }

    dynamic "copy_action" {
      for_each = each.value.rule.copy_action[*]
      content {
        destination_vault_arn = copy_action.value.destination_vault_arn

        dynamic "lifecycle" {
          for_each = copy_action.value.lifecycle[*]
          content {
            cold_storage_after = lifecycle.value.cold_storage_after
            delete_after       = lifecycle.value.delete_after
          }
        }
      }
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = each.value.advanced_backup_setting[*]
    content {
      backup_options = advanced_backup_setting.value.backup_options
      resource_type  = advanced_backup_setting.value.resource_type
    }
  }

}

resource "aws_backup_selection" "selection" {
  for_each = local.plans

  iam_role_arn = aws_iam_role.backup_service_role.arn
  name         = "${each.key}-selection"
  plan_id      = aws_backup_plan.plan[each.key].id

  dynamic "selection_tag" {
    for_each = each.value.selection[*]

    content {
      type  = selection_tag.value.selection_tag.type
      key   = selection_tag.value.selection_tag.key
      value = selection_tag.value.selection_tag.value
    }
  }

  resources = each.value.resources
}

locals {

  plans = { for plan, conf in var.plans :
    plan => {
      custom_iam_role_arn = lookup(conf, "custom_iam_role_arn", null)
      rule = {
        rule_name                = lookup(conf.rule, "rule_name", "${plan}-rule")
        target_vault_name        = lookup(conf.rule, "target_vault_name", null),
        schedule                 = lookup(conf.rule, "schedule", null),
        enable_continuous_backup = lookup(conf.rule, "enable_continuous_backup", false)
        start_window             = lookup(conf.rule, "start_window", null),
        completion_window        = lookup(conf.rule, "completion_window", null),
        # If user defined a lifecycle map, inline it, otherwise set lifecycle to null
        lifecycle = (lookup(conf.rule, "lifecycle", null) != null) ? {
          cold_storage_after = lookup(conf.rule.lifecycle, "cold_storage_after", null)
          delete_after       = lookup(conf.rule.lifecycle, "delete_after", null),
        } : null,

        recovery_point_tags = lookup(conf.rule, "recovery_point_tags", null),
        copy_action         = lookup(conf.rule, "copy_action", null)
      }
      # If user defined an advanced_backup_setting  map, inline it, otherwise set advanced_backup_setting to null
      advanced_backup_setting = (lookup(conf, "advanced_backup_setting", null) != null) ? {
        backup_options = {
          WindowsVSS = "enabled"
        }
        resource_type = "EC2"
      } : null,
      selection = {
        selection_tag = {
          type  = lookup(conf.selection.selection_tag, "type", "STRINGEQUALS"),
          key   = lookup(conf.selection.selection_tag, "key", "Snapshot"),
          value = lookup(conf.selection.selection_tag, "value", "true"),
        }
      }
      resources = lookup(conf, "resources", [])
    }
  }

}
