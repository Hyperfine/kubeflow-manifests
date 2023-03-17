# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN RDS CLUSTER WITH AMAZON AURORA SERVERLESS
# This template shows an example of how to use the aurora module to launch an
# RDS cluster with Amazon Aurora Serverless. The cluster is managed by AWS and
# automatically handles failover, backups, patching, and encryption.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# LAUNCH AURORA SERVERLESS ON RDS
# ------------------------------------------------------------------------------

module "aurora_serverless" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  name                = var.name
  master_username     = var.master_username
  master_password     = var.master_password
  engine              = var.engine
  apply_immediately   = var.apply_immediately
  skip_final_snapshot = true

  # You must have encrypted storage when using serverless mode.
  engine_mode       = "serverless"
  storage_encrypted = true

  # aurora serverless automatically manages the instances
  instance_count = 0
  instance_type  = ""

  # scaling configuration
  scaling_configuration_auto_pause               = var.scaling_configuration_auto_pause
  scaling_configuration_min_capacity             = var.scaling_configuration_min_capacity
  scaling_configuration_max_capacity             = var.scaling_configuration_max_capacity
  scaling_configuration_seconds_until_auto_pause = var.scaling_configuration_seconds_until_auto_pause
  scaling_configuration_timeout_action           = var.scaling_configuration_timeout_action

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means the DB is accessible from
# the public Internet. For a production deployment, we strongly recommend deploying into a custom VPC with private
# subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
