# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A ROUTE 53 HEALTH CHECK
# This is an example of how to create a Route 53 health check that monitors a given domain and triggers an alarm if
# that domain goes down.
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

# ------------------------------------------------------------------------------
# CREATE A ROUTE 53 HEALTH CHECK
# ------------------------------------------------------------------------------

module "route53_health_check" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/route53-health-check-alarms?ref=v1.0.8"
  source                         = "../../modules/alarms/route53-health-check-alarms"
  domain                         = var.domain
  alarm_sns_topic_arns_us_east_1 = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or
# SMS. NOTE: We explicitly force the SNS topic to live in the us-east-1 region because Route 53 sends all of its
# CloudWatch metrics to that region, and therefore, the health check, alarm, and SNS topic must also be in that region.
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  alias  = "east-1"
  region = "us-east-1"
}

resource "aws_sns_topic" "cloudwatch_alarms" {
  provider = aws.east-1
  name     = "${var.name}-route53-health-check-alarms"
}
