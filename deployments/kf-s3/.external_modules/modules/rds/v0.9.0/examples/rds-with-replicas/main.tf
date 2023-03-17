# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# LAUNCH AN RDS CLUSTER WITH A READ REPLICA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
# AN EXAMPLE OF A MYSQL RDS CLUSTER WITH READ REPLICAS
# ------------------------------------------------------------------------------

module "mysql_example" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-modules.git//modules/data-storage/rds?ref=v1.0.8"
  source = "../../modules/rds"

  name           = "${var.name}-mysql"
  engine         = "mysql"
  engine_version = "5.6.37"
  port           = 3306

  master_username = var.master_username
  master_password = var.master_password

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make this example simple to test, we allow incoming connections from any IP, but in real-world usage, you should
  # lock this down to the IPs of trusted servers
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  # Enable 1 read replica for this example
  num_read_replicas       = 1
  backup_retention_period = 1

  # Since this is just an example, we are using a small DB instance with only 10GB of storage and no standby. You'll
  # want to tweak all of these settings for production usage.
  instance_type = "db.t2.micro"

  allocated_storage   = 10
  multi_az            = false
  skip_final_snapshot = true
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
