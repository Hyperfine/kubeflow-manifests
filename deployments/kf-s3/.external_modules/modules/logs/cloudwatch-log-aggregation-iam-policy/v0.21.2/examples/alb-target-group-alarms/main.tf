# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN ALB TARGET GROUP AND ADD CLOUDWATCH ALARMS TO IT
# This is an example of how to create an ALB Target Group and attach a set of useful CloudWatch alarms. Note that, in
# production, you will want to use the Gruntwork Module module-ecs/ecs-service-with-alb to generate a Target Group, versus
# creating a Target Group on your own.
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
# CREATE THE ALB AND TARGET GROUP
# We create both an ALB and a Target Group because many of our metrics require
# ---------------------------------------------------------------------------------------------------------------------

module "alb" {
  source = "git::git@github.com:gruntwork-io/module-load-balancer.git//modules/alb?ref=v0.14.1"

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region

  alb_name         = var.alb_name
  environment_name = "test"
  is_internal_alb  = false

  http_listener_ports                = [80]
  https_listener_ports_and_ssl_certs = []
  ssl_policy                         = "ELBSecurityPolicy-TLS-1-1-2017-01"

  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.subnet_ids

  enable_alb_access_logs = false
}

resource "aws_alb_target_group" "test" {
  name     = "${var.alb_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ALARMS FOR THE ELB
# ---------------------------------------------------------------------------------------------------------------------

module "alb_tg_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/alb-target-group-alarms?ref=v1.0.8"
  source                              = "../../modules/alarms/alb-target-group-alarms"
  alb_arn                             = module.alb.alb_arn
  alb_name                            = module.alb.alb_name
  target_group_name                   = aws_alb_target_group.test.name
  target_group_arn                    = aws_alb_target_group.test.arn
  alarm_sns_topic_arns                = [aws_sns_topic.cloudwatch_alarms.arn]
  tg_low_healthy_host_count_threshold = 1
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SNS TOPIC WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.alb_name}-alb-alarms"
}
