# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN AUTO SCALING GROUP AND ADD CLOUDWATCH ALARMS TO IT
# This is an example of how to create an Auto Scaling Group (ASG) to run several EC2 Instances and how to attach
# alarms to the instances in that ASG that go off if CPU, memory, or disk space usage are too high.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
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
# CREATE THE AUTO SCALING GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "example" {
  name                 = var.name
  availability_zones   = data.aws_availability_zones.available.names
  max_size             = 2
  min_size             = 2
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.example.name

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }
}

# Get a list of Availability Zones in the current region
data "aws_availability_zones" "available" {}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE LAUNCH CONFIGURATION
# This defines what runs on each EC2 Instance in the Auto Scaling Group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_configuration" "example" {
  name_prefix   = "${var.name}-"
  image_id      = var.ami
  instance_type = "t2.micro"

  # Important note: whenever using a launch configuration with an auto scaling group, you must set
  # create_before_destroy = true. However, as soon as you set create_before_destroy = true in one resource, you must
  # also set it in every resource that it depends on, or you'll get an error about cyclic dependencies (especially when
  # removing resources). For more info, see:
  #
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  # https://terraform.io/docs/configuration/resources.html
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALARM FOR HIGH CPU USAGE
# ---------------------------------------------------------------------------------------------------------------------

module "asg_high_cpu_usage_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/asg-cpu-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/asg-cpu-alarms"
  asg_names            = [aws_autoscaling_group.example.name]
  num_asg_names        = 1
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALARM FOR HIGH MEMORY USAGE
# ---------------------------------------------------------------------------------------------------------------------

module "asg_high_memory_usage_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/asg-memory-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/asg-memory-alarms"
  asg_names            = [aws_autoscaling_group.example.name]
  num_asg_names        = 1
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ALARM FOR HIGH DISK USAGE
# ---------------------------------------------------------------------------------------------------------------------

module "asg_high_disk_usage_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/asg-disk-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/asg-disk-alarms"
  asg_names            = [aws_autoscaling_group.example.name]
  num_asg_names        = 1
  file_system          = "/dev/xvda1"
  mount_path           = "/"
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.name}-asg-alarms"
}
