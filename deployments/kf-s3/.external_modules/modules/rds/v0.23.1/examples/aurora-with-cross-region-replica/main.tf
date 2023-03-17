# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN RDS CLUSTER WITH AMAZON AURORA AND CROSS-REGION REPLICATION
# This template shows an example of how to use the aurora module to launch an
# RDS cluster with Amazon Aurora and cross-region replication. The cluster is
# managed by AWS and automatically handles leader election, replication,
# failover, backups, patching, and encryption.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0"
    }
  }
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

provider "aws" {
  region = var.replica_region
  alias  = "replica"
}

# ------------------------------------------------------------------------------
# CREATE A PARAMETER GROUP WITH BINLOG REPLICATION ENABLED
# ------------------------------------------------------------------------------

resource "aws_rds_cluster_parameter_group" "primary" {
  provider = aws.primary

  family = "aurora5.6"
  parameter {
    name         = "binlog_format"
    value        = "MIXED"
    apply_method = "pending-reboot"
  }
}

# ------------------------------------------------------------------------------
# LAUNCH AURORA ON RDS
# ------------------------------------------------------------------------------

module "aurora_primary" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  providers = {
    aws = aws.primary
  }

  name                            = "${var.name}-primary"
  master_username                 = var.master_username
  master_password                 = var.master_password
  engine_mode                     = var.engine_mode
  engine                          = "aurora"
  engine_version                  = "5.6.10a"
  storage_encrypted               = var.storage_encrypted
  kms_key_arn                     = var.storage_encrypted == true ? module.kms_master_key[0].key_arn[var.name] : null
  apply_immediately               = var.apply_immediately
  skip_final_snapshot             = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.primary.name

  instance_count = var.instance_count
  instance_type  = var.instance_type

  vpc_id     = data.aws_vpc.primary.id
  subnet_ids = data.aws_subnet_ids.primary.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  create_subnet_group      = var.create_subnet_group
  aws_db_subnet_group_name = var.aws_db_subnet_group_name
}

module "aurora_replica" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/aurora?ref=v1.0.8"
  source = "../../modules/aurora"

  providers = {
    aws = aws.replica
  }

  name                = "${var.name}-replica"
  engine_mode         = var.engine_mode
  engine              = "aurora"
  engine_version      = "5.6.10a"
  storage_encrypted   = var.storage_encrypted
  kms_key_arn         = var.storage_encrypted == true ? module.kms_master_key_replica[0].key_arn[var.name] : null
  apply_immediately   = var.apply_immediately
  skip_final_snapshot = true

  replication_source_identifier = module.aurora_primary.cluster_arn
  source_region                 = var.primary_region

  instance_count = var.instance_count
  instance_type  = var.instance_type

  vpc_id     = data.aws_vpc.replica.id
  subnet_ids = data.aws_subnet_ids.replica.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  create_subnet_group      = var.create_subnet_group
  aws_db_subnet_group_name = var.aws_db_subnet_group_name

  dependencies = [module.aurora_primary.instance_endpoints[0]]
}

module "kms_master_key" {
  count  = var.storage_encrypted == true ? 1 : 0
  source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/kms-master-key?ref=v0.55.1"

  providers = {
    aws = aws.primary

  }

  customer_master_keys = {
    (var.name) = {
      deletion_window_in_days    = 7
      cmk_administrator_iam_arns = var.cmk_administrator_iam_arns
      cmk_user_iam_arns          = var.cmk_user_iam_arns
      cmk_service_principals     = []
    }
  }
}

module "kms_master_key_replica" {
  count  = var.storage_encrypted == true ? 1 : 0
  source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/kms-master-key?ref=v0.55.1"

  providers = {
    aws = aws.replica
  }

  customer_master_keys = {
    (var.name) = {
      deletion_window_in_days    = 7
      cmk_administrator_iam_arns = var.cmk_administrator_iam_arns
      cmk_user_iam_arns          = var.cmk_user_iam_arns
      cmk_service_principals     = []
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means the DB is accessible from
# the public Internet. For a production deployment, we strongly recommend deploying into a custom VPC with private
# subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "primary" {
  provider = aws.primary
  default  = true
}

data "aws_subnet_ids" "primary" {
  provider = aws.primary
  vpc_id   = data.aws_vpc.primary.id
}

data "aws_vpc" "replica" {
  provider = aws.replica
  default  = true
}

data "aws_subnet_ids" "replica" {
  provider = aws.replica
  vpc_id   = data.aws_vpc.replica.id
}
