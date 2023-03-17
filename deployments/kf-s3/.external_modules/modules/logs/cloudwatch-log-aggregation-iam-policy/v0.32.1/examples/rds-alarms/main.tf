# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN RDS INSTANCE AND ADD CLOUDWATCH ALARMS TO IT
# This is an example of how to create an Relational Database Service (RDS) Instance running Postgres and how to attach
# alarms to it that go off if if the CPU usage, number of connections, or latency gets too high or if the available
# memory or disk space gets too low
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

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  # Only this AWS Account ID may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE RDS INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

module "postgres" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-data-storage.git//modules/rds?ref=v0.21.1"

  name           = var.db_name
  engine         = "postgres"
  engine_version = "9.6"
  port           = 5432

  master_username = var.master_username
  master_password = var.master_password

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # To make testing easier, we allow connections from anywhere in this example, but you should NEVER do this in
  # real-world usage. If you're using the standard Gruntwork VPC, you should instead only accept connections from
  # the private app subnets CIDR blocks.
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  # Since this is just an example for testing, we are using a small DB instance with only 10GB of storage, no standby,
  # no replicas, and no automatic backups.
  instance_type           = "db.t3.micro"
  allocated_storage       = 10
  multi_az                = false
  num_read_replicas       = 0
  backup_retention_period = 0
  skip_final_snapshot     = true
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ALARMS FOR THE RDS INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

module "rds_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/rds-alarms?ref=v1.0.8"
  source                            = "../../modules/alarms/rds-alarms"
  num_rds_instance_ids              = 1
  rds_instance_ids                  = [module.postgres.primary_id]
  too_many_db_connections_threshold = 10
  alarm_sns_topic_arns              = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.db_name}-rds-alarms"
}
