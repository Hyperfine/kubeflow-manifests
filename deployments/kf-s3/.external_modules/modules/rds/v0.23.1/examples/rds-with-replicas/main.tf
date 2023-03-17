# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN RDS CLUSTER WITH A READ REPLICA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.1.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"

      # Requirement for RDS Storage Auto Scaling
      # https://github.com/hashicorp/terraform-provider-aws/issues/9076#issuecomment-506569551
      version = ">= 2.17, < 4.0"
    }
  }
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# AN EXAMPLE OF A MYSQL RDS CLUSTER WITH READ REPLICAS
# ------------------------------------------------------------------------------

module "mysql_example" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-modules.git//modules/rds?ref=v1.0.8"
  source = "../../modules/rds"

  name           = "${var.name}-mysql"
  engine         = "mysql"
  engine_version = "8.0.27"
  port           = 3306

  master_username = var.master_username
  master_password = var.master_password

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  # An example of how to set different CIDR blocks for read replicas
  allow_connections_from_cidr_blocks_to_read_replicas = ["10.10.0.0/16"]

  # Enable 1 read replica for this example
  num_read_replicas       = 1
  backup_retention_period = 1

  # An example of how to set different db parameter group for read replicas
  parameter_group_name_for_read_replicas = aws_db_parameter_group.parameter_group_read_replica.name

  # Since this is just an example, we are using a small DB instance with only 10GB of storage and no standby. You'll
  # want to tweak all of these settings for production usage.
  instance_type = "db.t3.micro"

  allocated_storage     = 10
  max_allocated_storage = 50
  multi_az              = false
  skip_final_snapshot   = true
  storage_encrypted     = var.storage_encrypted
}

# ------------------------------------------------------------------------------
# AN EXAMPLE OF HOW TO CREATE CUSTOM PARAMETERS GROUP FOR THE READ REPLICA INSTANCE
# ------------------------------------------------------------------------------

resource "aws_db_parameter_group" "parameter_group_read_replica" {
  name_prefix = "${var.name}-mysql-read-replica-"
  description = "Database parameter group for ${var.name}-mysql read replica instances"
  family      = "mysql8.0"

  parameter {
    name         = "general_log"
    value        = "1"
    apply_method = "pending-reboot"
  }
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
