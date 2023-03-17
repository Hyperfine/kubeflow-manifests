# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN APPLICATION LOAD BALANCER AND ADD CLOUDWATCH ALARMS TO IT
# This is an example of how to deploy an Application Load Balancer (ALB) and attach alarms to it that go off if the latency
# gets too high, or there are too many 5xx errors, or too few requests are coming in.
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
# CREATE THE ALB
# ------------------------------------------------------------------------------

module "alb" {
  source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/alb?ref=v0.14.1"

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region

  alb_name         = var.alb_name
  environment_name = "terratest"
  is_internal_alb  = false

  http_listener_ports                = [80]
  https_listener_ports_and_ssl_certs = []
  ssl_policy                         = "ELBSecurityPolicy-TLS-1-1-2017-01"

  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.subnet_ids

  enable_alb_access_logs = false
}

# ------------------------------------------------------------------------------
# CREATE ALARMS FOR THE ALB
# ------------------------------------------------------------------------------

module "alb_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/alb-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/alb-alarms"
  alb_arn              = module.alb.alb_arn
  alb_name             = module.alb.alb_name
  alarm_sns_topic_arns = [aws_sns_topic.cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.alb_name}-alb-alarms"
}
