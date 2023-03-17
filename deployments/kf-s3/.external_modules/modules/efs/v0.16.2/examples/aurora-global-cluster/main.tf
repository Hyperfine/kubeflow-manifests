# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN RDS CLUSTER WITH AMAZON AURORA GLOBAL CLUSTER
# This template shows an example of how to use the aurora module to launch an
# RDS cluster with Amazon Aurora. The cluster is managed by AWS and automatically
# handles leader election, replication, failover, backups, patching, and encryption.
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
# LAUNCH AURORA GLOBAL CLUSTER ON RDS
# ------------------------------------------------------------------------------

resource "aws_rds_global_cluster" "global_cluster" {
  global_cluster_identifier = "global-${var.name}"

  database_name = "mydb"

  engine              = var.engine
  engine_version      = var.engine_version
  storage_encrypted   = var.storage_encrypted
  deletion_protection = var.deletion_protection
}

module "aurora_global_cluster_primary" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  global_cluster_identifier = aws_rds_global_cluster.global_cluster.id

  name                = "${var.name}-1"
  engine              = var.engine
  engine_mode         = var.engine_mode
  engine_version      = var.engine_version
  instance_type       = var.instance_type
  instance_count      = var.instance_count
  master_username     = var.master_username
  master_password     = var.master_password
  storage_encrypted   = var.storage_encrypted
  skip_final_snapshot = true # don't leave a final snapshot when testing the example

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids
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
