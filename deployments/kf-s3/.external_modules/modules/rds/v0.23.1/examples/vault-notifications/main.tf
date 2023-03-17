# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Deploy an AWS Backup Vault with a basic plan and selection
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.42.0, < 4.0"
    }
  }
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE AWS BACKUP VAULT
# ---------------------------------------------------------------------------------------------------------------------

module "backup_vault" {

  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-catalog.git//modules/backup-vault?ref=v1.0.8"
  source = "../../modules/backup-vault"

  vaults = {
    # Configure a new vault, and enable notifications. Vault notifications allows vaults to
    # publish events to an SNS topic for monitoring purposes
    "vault-with-notifications-${var.name}" = {
      enable_notifications = true
      # If you wish to specify which AWS Backup events to listen to, you can pass them like so
      # events_to_listen_for = ["BACKUP_JOB_STARTED", "BACKUP_JOB_COMPLETED"]
      # If you do not pass events_to_listen_for, then all AWS Backup events will be listened for
    }
  }
}

module "backup_plan" {

  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-catalog.git//modules/backup-plan?ref=v1.0.8"
  source = "../../modules/backup-plan"

  backup_service_role_name = var.backup_service_role_name

  plans = {
    # Create a Backup plan and associate it with the vault that was just configured above
    "backup-plan-${var.name}" = {
      rule = {
        target_vault_name = "vault-with-notifications-${var.name}"
        # Run the Backup jobs every hour on the first minute past the hour (or after)
        schedule = "cron(1 0/1 * * ? *)"
      }
      selection = {
        # Select for Backup all resources tagged with Snapshot:true
        selection_tag = {
          type  = "STRINGEQUALS"
          key   = "Snapshot"
          value = true
        }
      }
    }
  }
}
