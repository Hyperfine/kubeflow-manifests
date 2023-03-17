# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A SCHEDULED JOB ALARM
# This is an example of how to create an alarm that goes off if a scheduled job (e.g. a cron job) fails to run and
# increment a given CloudWatch metric within a given time period.
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
# CREATE THE SCHEDULED JOB ALARM
# ---------------------------------------------------------------------------------------------------------------------

module "scheduled_job_alarm" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-monitoring.git//modules/alarms/scheduled-job-alarm?ref=v1.0.8"
  source = "../../modules/alarms/scheduled-job-alarm"

  name                 = var.name
  namespace            = var.namespace
  metric_name          = var.metric_name
  period               = 60
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.name}-scheduled-job-alararms"
}
