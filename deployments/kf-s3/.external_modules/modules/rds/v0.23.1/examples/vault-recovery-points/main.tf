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
# CREATE THE AWS EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    "Snapshot-${var.name}" = true
  }
}

data "aws_caller_identity" "current" {}
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE AWS BACKUP VAULT
# ---------------------------------------------------------------------------------------------------------------------

module "backup_vault" {

  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-catalog.git//modules/backup-vault?ref=v1.0.8"
  source = "../../modules/backup-vault"

  vaults = {
    # Create a new vault with no lock or notifications
    "test-vault-recovery-points-${var.name}" = {}
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
    "recovery-point-test-plan-${var.name}" = {
      rule = {
        target_vault_name = "test-vault-recovery-points-${var.name}"
        # Run the backup plan at 23:01 every day
        schedule = "cron(1 23 * * ? *)"
      }
      selection = {
        # Select for Backup all resources tagged with "Snapshot-${var.name}":true
        # In order for our automated tests to check that backups are actually being created, we are intentionally creating tag selections that will only match the resources created in this example and nothing else
        selection_tag = {
          type  = "STRINGEQUALS"
          key   = "Snapshot-${var.name}"
          value = true
        }
      }
    }
  }
}
