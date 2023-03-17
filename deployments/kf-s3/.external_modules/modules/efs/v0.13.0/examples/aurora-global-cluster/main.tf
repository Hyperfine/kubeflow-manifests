# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN RDS CLUSTER WITH AMAZON AURORA GLOBAL CLUSTER
# This template shows an example of how to use the aurora module to launch an
# RDS cluster with Amazon Aurora. The cluster is managed by AWS and automatically
# handles leader election, replication, failover, backups, patching, and encryption.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
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
  storage_encrypted         = var.storage_encrypted
  engine_version            = var.engine_version
  global_cluster_identifier = "global-${var.name}"
}

module "aurora_global_cluster_primary" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  name                = "${var.name}-1"
  db_name             = "mydb"
  master_username     = var.master_username
  master_password     = var.master_password
  engine_mode         = var.engine_mode
  storage_encrypted   = var.storage_encrypted
  skip_final_snapshot = true

  global_cluster_identifier = aws_rds_global_cluster.global_cluster.id

  instance_count = var.instance_count
  instance_type  = "db.r5.large"
  is_primary     = var.is_primary
  vpc_id         = data.aws_vpc.default.id
  subnet_ids     = data.aws_subnet_ids.default.ids

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
