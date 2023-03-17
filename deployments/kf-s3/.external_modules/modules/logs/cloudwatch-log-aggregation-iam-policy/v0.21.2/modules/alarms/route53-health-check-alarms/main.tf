# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE A ROUTE 53 HEALTH CHECK THAT TRIGGERS AN ALARM IF YOUR SITE IS DOWN
# Note: Route 53 only sends its CloudWatch metrics to us-east-1, so the health check, alarm, and SNS topic must ALL
# live in us-east-1 as well. See https://github.com/hashicorp/terraform/issues/7371 for details.
# ----------------------------------------------------------------------------------------------------------------------

provider "aws" {
  alias  = "east-1"
  region = "us-east-1"
}

resource "aws_route53_health_check" "site_is_up" {
  count = var.create_resources ? 1 : 0

  provider          = aws.east-1
  fqdn              = var.domain
  port              = var.port
  type              = var.type
  resource_path     = var.path
  failure_threshold = var.failure_threshold
  request_interval  = var.request_interval

  tags = {
    Name = "${var.domain}-is-up-http"
  }
}

resource "aws_cloudwatch_metric_alarm" "site_is_up" {
  count = var.create_resources ? 1 : 0

  provider          = aws.east-1
  alarm_name        = "${var.domain}-is-up"
  alarm_description = "An alarm that goes off if the route 53 health check reports that ${var.domain} is down"
  namespace         = "AWS/Route53"
  metric_name       = "HealthCheckStatus"

  dimensions = {
    HealthCheckId = aws_route53_health_check.site_is_up.*.id[count.index]
  }

  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  period                    = "60"
  statistic                 = "Minimum"
  threshold                 = "1"
  unit                      = "None"
  alarm_actions             = var.alarm_sns_topic_arns_us_east_1
  ok_actions                = var.alarm_sns_topic_arns_us_east_1
  insufficient_data_actions = var.alarm_sns_topic_arns_us_east_1
  tags                      = var.tags
}
