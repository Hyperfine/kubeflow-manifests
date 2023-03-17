# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN EC2 INSTANCE AND ADD CLOUDWATCH ALARMS TO IT
# This is an example of how to deploy an EC2 Instance and attach alarms to the instance that go off if CPU, memory, or
# disk space usage are too high.
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
# CREATE THE EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = module.instance_type.recommended_instance_type
  tags = {
    Name = var.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PICK AN INSTANCE TYPE
# We run automated tests against this example code in many regions, and some AZs in some regions don't have certain
# instance types. Therefore, we use this module to pick an instance type that's available in all AZs in the current
# region.
# ---------------------------------------------------------------------------------------------------------------------

module "instance_type" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-utilities.git//modules/instance-type?ref=v0.4.0"

  instance_types = ["t3.micro", "t2.micro"]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALARM FOR HIGH CPU USAGE
# ---------------------------------------------------------------------------------------------------------------------

module "ec2_high_cpu_usage_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/ec2-cpu-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/ec2-cpu-alarms"
  instance_ids         = [aws_instance.example.id]
  instance_count       = 1
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALARM FOR HIGH MEMORY USAGE
# ---------------------------------------------------------------------------------------------------------------------

module "ec2_high_memory_usage_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/ec2-memory-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/ec2-memory-alarms"
  instance_ids         = [aws_instance.example.id]
  instance_type        = aws_instance.example.instance_type
  instance_count       = 1
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALARM FOR HIGH DISK USAGE
# ---------------------------------------------------------------------------------------------------------------------

module "ec2_high_disk_usage_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/ec2-disk-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/ec2-disk-alarms"
  instance_ids         = [aws_instance.example.id]
  instance_type        = aws_instance.example.instance_type
  ami                  = aws_instance.example.ami
  instance_count       = 1
  device               = "xvda1"
  mount_path           = "/"
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
  fstype               = "ext4"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.name}-ec2-alarms"
}
