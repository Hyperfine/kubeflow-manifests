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
# CREATE THE AWS BACKUP PLAN AND SELECTION
# ---------------------------------------------------------------------------------------------------------------------

# Create a Backup plan, but do not create a Backup vault. Instead, use the Default vault that exists in every region once your AWS account has opted-in to use AWS Backup.
# See core-concepts.md in this module directory for more information on getting started with AWS Backup.

module "backup_plan" {

  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-catalog.git//modules/backup-plan?ref=v1.0.8"
  source = "../../modules/backup-plan"

  backup_service_role_name = var.backup_service_role_name

  plans = {
    # Create a Backup plan and associate it with the Default Backup vault in the given region
    "${var.name}" = {
      rule = {
        # Use the Default vault instead of creating a new one
        target_vault_name = "Default"
        # Run the Backup jobs every hour at 33 minutes (or more) past the hour
        schedule = "cron(33 0/1 * * ? *)"
      }
      selection = {
        # Target all eligible resources that are tagged with Snapshot: true for backups
        selection_tag = {
          type  = "STRINGEQUALS"
          key   = "Snapshot"
          value = true
        }
      }
    }
  }
}
