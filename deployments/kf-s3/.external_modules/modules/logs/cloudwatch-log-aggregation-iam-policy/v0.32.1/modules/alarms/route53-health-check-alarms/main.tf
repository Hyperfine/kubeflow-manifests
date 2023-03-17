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

# ----------------------------------------------------------------------------------------------------------------------
# CREATE A ROUTE 53 HEALTH CHECK THAT TRIGGERS AN ALARM IF YOUR SITE IS DOWN
# Note: Route 53 only sends its CloudWatch metrics to us-east-1, so the health check, alarm, and SNS topic must ALL
# live in us-east-1 as well. See https://github.com/hashicorp/terraform/issues/7371 for details.
# ----------------------------------------------------------------------------------------------------------------------

provider "aws" {
  alias  = "east-1"
  region = "us-east-1"

  assume_role {
    role_arn     = var.provider_role_arn
    external_id  = var.provider_external_id
    session_name = var.provider_session_name
  }

  profile                 = var.provider_profile
  shared_credentials_file = var.provider_shared_credentials_file
}

resource "aws_route53_health_check" "site_is_up" {
  for_each = var.create_resources ? local.alarm_configs : {}

  reference_name    = each.key
  provider          = aws.east-1
  fqdn              = each.value.domain
  port              = each.value.port
  type              = each.value.type
  resource_path     = each.value.path
  failure_threshold = each.value.failure_threshold
  request_interval  = each.value.request_interval

  tags = {
    Name = "${each.value.domain}-is-up-http"
  }
}

resource "aws_cloudwatch_metric_alarm" "site_is_up" {
  for_each = var.create_resources ? local.alarm_configs : {}

  provider          = aws.east-1
  alarm_name        = "${each.value.domain}-is-up"
  alarm_description = "An alarm that goes off if the route 53 health check reports that ${each.value.domain} is down"
  namespace         = "AWS/Route53"
  metric_name       = "HealthCheckStatus"

  dimensions = {
    HealthCheckId = aws_route53_health_check.site_is_up[each.key].id
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
  tags                      = each.value.tags
}

locals {
  alarm_configs = {
    for key, alarm_config in var.alarm_configs :
    key => {
      // No default value for "domain" since it is required
      domain            = lookup(alarm_config, "domain")
      port              = lookup(alarm_config, "port", 80)
      type              = lookup(alarm_config, "type", "HTTP")
      path              = lookup(alarm_config, "path", "/")
      failure_threshold = lookup(alarm_config, "failure_threshold", 2)
      request_interval  = lookup(alarm_config, "request_interval", 30)
      tags              = lookup(alarm_config, "tags", null) == null ? {} : alarm_config.tags
    }
  }
}
