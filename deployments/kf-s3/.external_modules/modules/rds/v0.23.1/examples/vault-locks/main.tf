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
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-catalog.git//modules/data-stores?ref=v1.0.8"
  source = "../../modules/backup-vault"

  vaults = {
    # Create a vault, and then lock the vault, which prevents any recovery points stored
    # in the vault from being accidentally or maliciously deleted
    "locked-vault-${var.name}" = {
      locked = true
      # Set the lock "cooling-off period" to 5 days, which means you will have 5 days to edit or
      # delete the lock. Once your lock takes affect, you cannot delete or alter an AWS Backup
      # vault lock using the Console, API, CLI or SDK!
      # Note that, by default, AWS will set the cooling-off period to 3 days
      changeable_for_days = 5
      # Ensure recovery points are retained for at least 30 days
      min_retention_days = 30
      # Set the maximum number of days a Backup plan can specify for retention of recovery points
      max_retention_days = 120
    }
  }
}

module "backup_plan" {

  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-catalog.git//modules/backup-plan?ref=v1.0.8"
  source = "../../modules/backup-plan"

  backup_service_role_name = var.backup_service_role_name
  # Create a Backup plan and associate it with the vault that was just configured above
  plans = {
    "tagged-backup-plan-${var.name}" = {
      rule = {
        target_vault_name = element(module.backup_vault.vault_names, 0),
        # Run the backup job once per hour on or after the 1st minute
        schedule = "cron(1 0/1 * * ? *)"
      }
      selection = {
        # Select for backup all resources tagged with Snapshot:true
        selection_tag = {
          type  = "STRINGEQUALS"
          key   = "Snapshot"
          value = true
        }
      }
    }
  }
}
