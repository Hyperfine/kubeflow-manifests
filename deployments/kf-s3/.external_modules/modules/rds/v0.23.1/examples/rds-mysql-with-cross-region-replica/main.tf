# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH A MYSQL RDS CLUSTER WITH A REPLICA IN ANOTHER REGION
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
# LAUNCH THE PRIMARY
# ------------------------------------------------------------------------------

module "mysql_primary" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/rds?ref=v1.0.8"
  source = "../../modules/rds"

  providers = {
    aws = aws.primary
  }

  name           = "${var.name}-mysql-primary"
  engine         = "mysql"
  engine_version = var.mysql_engine_version
  port           = 3306

  master_username = var.master_username
  master_password = var.master_password

  vpc_id     = data.aws_vpc.primary.id
  subnet_ids = data.aws_subnet_ids.primary.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  # Since this is just an example, we are using a small DB instance with only 10GB of storage, no standby, no replicas,
  # and no automatic backups. You'll want to tweak all of these settings for production usage.
  instance_type = "db.t3.micro"

  apply_immediately     = true
  allocated_storage     = 10
  max_allocated_storage = 50
  multi_az              = false
  num_read_replicas     = 0

  # Must be set to 1 or greater to support replicas
  backup_retention_period = 1

  # Solely disabled to make testing faster. You should NOT disable this in prod.
  skip_final_snapshot = true

  storage_encrypted = var.storage_encrypted
}

# ------------------------------------------------------------------------------
# LAUNCH THE REPLICA IN ANOTHER REGION
# ------------------------------------------------------------------------------

module "mysql_replica" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/rds?ref=v1.0.8"
  source = "../../modules/rds"

  providers = {
    aws = aws.replica
  }

  # To indicate this is a replica of the primary, we set the replicate_source_db param
  replicate_source_db = module.mysql_primary.primary_arn

  name           = "${var.name}-mysql-replica"
  engine         = "mysql"
  engine_version = var.mysql_engine_version
  port           = 3306

  vpc_id     = data.aws_vpc.replica.id
  subnet_ids = data.aws_subnet_ids.replica.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  # Since this is just an example, we are using a small DB instance with only 10GB of storage, no standby, no replicas,
  # and no automatic backups. You'll want to tweak all of these settings for production usage.
  instance_type = "db.t3.micro"

  apply_immediately       = true
  max_allocated_storage   = 50
  multi_az                = false
  num_read_replicas       = 0
  backup_retention_period = 0
  skip_final_snapshot     = true
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
