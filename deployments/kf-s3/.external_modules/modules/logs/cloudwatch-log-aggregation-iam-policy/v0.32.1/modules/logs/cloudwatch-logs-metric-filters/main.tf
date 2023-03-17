# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AWS CLOUDWATCH LOGS METRIC FILTERS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
# Create a Cloudwatch Logs Metric Filter
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  for_each       = var.metric_map
  name           = each.key
  pattern        = each.value.pattern
  log_group_name = var.cloudwatch_logs_group_name

  metric_transformation {
    name      = each.key
    namespace = var.metric_namespace
    value     = "1"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Create a Cloudwatch Metric Alarm
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "metric_alarm" {
  for_each = var.metric_map

  alarm_name        = each.key
  alarm_description = each.value.description

  namespace   = var.metric_namespace
  metric_name = each.key

  comparison_operator = var.alarm_comparison_operator
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period
  statistic           = var.alarm_statistic
  treat_missing_data  = var.alarm_treat_missing_data
  threshold           = var.alarm_threshold

  insufficient_data_actions = [local.sns_topic_arn]
  ok_actions                = [local.sns_topic_arn]
  alarm_actions             = [local.sns_topic_arn]
}

# The SNS topic to use for metric alerts
resource "aws_sns_topic" "alarm_topic" {
  count             = var.sns_topic_already_exists ? 0 : 1
  name              = var.sns_topic_name
  kms_master_key_id = var.sns_topic_kms_master_key_id
}

locals {
  sns_topic_arn = var.sns_topic_arn != null ? var.sns_topic_arn : aws_sns_topic.alarm_topic[0].arn
}
