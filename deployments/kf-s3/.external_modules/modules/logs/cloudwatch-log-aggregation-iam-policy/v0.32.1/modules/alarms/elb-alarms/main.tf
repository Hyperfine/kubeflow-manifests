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
# CREATE CLOUDWATCH ALARMS FOR ELB METRICS
# For detailed explanations of these metrics, see:
# http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/elb-cloudwatch-metrics.html
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "elb_backend_connection_errors" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.elb_name}-backend-connection-errors"
  alarm_description = "An alarm that goes off if the ELB ${var.elb_name} too often fails to establish a connection between itself and the registered EC2 Instances. NOTE: If this alarm is in INSUFFICIENT_DATA state, it usually means no errors are being reported, which actually means everything is working OK!"
  namespace         = "AWS/ELB"
  metric_name       = "BackendConnectionErrors"
  dimensions = {
    LoadBalancerName = var.elb_name
  }
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  period              = var.elb_backend_connection_error_period
  statistic           = "Sum"
  threshold           = var.elb_backend_connection_error_threshold
  unit                = "Count"
  alarm_actions       = var.alarm_sns_topic_arns
  ok_actions          = var.alarm_sns_topic_arns
  treat_missing_data  = var.elb_backend_connection_treat_missing_data
  tags                = var.tags
  # NOTE: The metric used in this alarm only reports data when there are errors. If there are no errors, it doesn't
  # report anything at all, so the alarm will go into the INSUFFICIENT_DATA state. Therefore, we should not send
  # notifications for the INSUFFICIENT_DATA state, as it may make it seem like something is broken, when it actually
  # means everything is working. See: https://forums.aws.amazon.com/thread.jspa?threadID=140404#jive-message-505459
  #
  # insufficient_data_actions = ["${var.alarm_sns_topic_arns}"]
}

resource "aws_cloudwatch_metric_alarm" "elb_too_many_backend_5xx" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.elb_name}-too-many-backend-5xx"
  alarm_description = "An alarm that goes off if the ELB ${var.elb_name} sees too many 5xx responses from the backends. NOTE: If this alarm is in INSUFFICIENT_DATA state, it usually means no errors are being reported, which actually means everything is working OK!"
  namespace         = "AWS/ELB"
  metric_name       = "HTTPCode_Backend_5XX"
  dimensions = {
    LoadBalancerName = var.elb_name
  }
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.elb_backend_5xx_evaluation_periods
  period              = var.elb_backend_5xx_period
  statistic           = "Sum"
  threshold           = var.elb_backend_5xx_threshold
  unit                = "Count"
  alarm_actions       = var.alarm_sns_topic_arns
  ok_actions          = var.alarm_sns_topic_arns
  treat_missing_data  = var.elb_backend_5xx_treat_missing_data
  tags                = var.tags
  # NOTE: The metric used in this alarm only reports data when there are errors. If there are no errors, it doesn't
  # report anything at all, so the alarm will go into the INSUFFICIENT_DATA state. Therefore, we should not send
  # notifications for the INSUFFICIENT_DATA state, as it may make it seem like something is broken, when it actually
  # means everything is working. See: https://forums.aws.amazon.com/thread.jspa?threadID=140404#jive-message-505459
  #
  # insufficient_data_actions = ["${var.alarm_sns_topic_arns}"]
}

resource "aws_cloudwatch_metric_alarm" "elb_too_many_5xx" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.elb_name}-too-many-5xx"
  alarm_description = "An alarm that goes off if there are no healthy instances registered to the ELB ${var.elb_name}. NOTE: If this alarm is in INSUFFICIENT_DATA state, it usually means no errors are being reported, which actually means everything is working OK!"
  namespace         = "AWS/ELB"
  metric_name       = "HTTPCode_ELB_5XX"
  dimensions = {
    LoadBalancerName = var.elb_name
  }
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.elb_5xx_evaluation_periods
  period              = var.elb_5xx_period
  statistic           = "Sum"
  threshold           = var.elb_5xx_threshold
  unit                = "Count"
  alarm_actions       = var.alarm_sns_topic_arns
  ok_actions          = var.alarm_sns_topic_arns
  treat_missing_data  = var.elb_5xx_treat_missing_data
  tags                = var.tags
  # NOTE: The metric used in this alarm only reports data when there are errors. If there are no errors, it doesn't
  # report anything at all, so the alarm will go into the INSUFFICIENT_DATA state. Therefore, we should not send
  # notifications for the INSUFFICIENT_DATA state, as it may make it seem like something is broken, when it actually
  # means everything is working. See: https://forums.aws.amazon.com/thread.jspa?threadID=140404#jive-message-505459
  #
  # insufficient_data_actions = ["${var.alarm_sns_topic_arns}"]
}

resource "aws_cloudwatch_metric_alarm" "elb_high_average_latency" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.elb_name}-high-average-latency"
  alarm_description = "An alarm that goes off if the average latency from the ELB ${var.elb_name} backends gets too high. NOTE: If this alarm is in INSUFFICIENT_DATA state, it's usually not an error, but just means no requests are going through the ELB."
  namespace         = "AWS/ELB"
  metric_name       = "Latency"
  dimensions = {
    LoadBalancerName = var.elb_name
  }
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.elb_high_average_latency_evaluation_periods
  period              = var.elb_high_average_latency_period
  statistic           = "Average"
  threshold           = var.elb_high_average_latency_threshold
  unit                = "Seconds"
  alarm_actions       = var.alarm_sns_topic_arns
  ok_actions          = var.alarm_sns_topic_arns
  treat_missing_data  = var.elb_high_average_latency_treat_missing_data
  tags                = var.tags
  # NOTE: The metric used in this alarm only reports data when there are requests going through the ELB. If there are
  # no requests, it doesn't report anything at all, so the alarm will go into the INSUFFICIENT_DATA state. Therefore,
  # we should not send notifications for the INSUFFICIENT_DATA state, as it may make it seem like something is broken,
  # when it actually means everything is working.
  #
  # insufficient_data_actions = ["${var.alarm_sns_topic_arns}"]
}

resource "aws_cloudwatch_metric_alarm" "elb_high_max_latency" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.elb_name}-high-max-latency"
  alarm_description = "An alarm that goes off if the maximum latency from the ELB ${var.elb_name} backends gets too high. NOTE: If this alarm is in INSUFFICIENT_DATA state, it's usually not an error, but just means no requests are going through the ELB."
  namespace         = "AWS/ELB"
  metric_name       = "Latency"
  dimensions = {
    LoadBalancerName = var.elb_name
  }
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.elb_high_max_latency_evaluation_periods
  period              = var.elb_high_max_latency_period
  statistic           = "Maximum"
  threshold           = var.elb_high_max_latency_threshold
  unit                = "Seconds"
  alarm_actions       = var.alarm_sns_topic_arns
  ok_actions          = var.alarm_sns_topic_arns
  treat_missing_data  = var.elb_high_max_latency_treat_missing_data
  tags                = var.tags
  # NOTE: The metric used in this alarm only reports data when there are requests going through the ELB. If there are
  # no requests, it doesn't report anything at all, so the alarm will go into the INSUFFICIENT_DATA state. Therefore,
  # we should not send notifications for the INSUFFICIENT_DATA state, as it may make it seem like something is broken,
  # when it actually means everything is working.
  #
  # insufficient_data_actions = ["${var.alarm_sns_topic_arns}"]
}

resource "aws_cloudwatch_metric_alarm" "elb_low_request_count" {
  # Only create this alarm if var.elb_low_request_count_threshold is greater than 0.
  count             = var.create_resources && var.elb_low_request_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.elb_name}-low-request-count"
  alarm_description = "An alarm that goes off if the number of requests the ELB ${var.elb_name} sees gets too low"
  namespace         = "AWS/ELB"
  metric_name       = "RequestCount"
  dimensions = {
    LoadBalancerName = var.elb_name
  }
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.elb_low_request_count_evaluation_periods
  period                    = var.elb_low_request_count_period
  statistic                 = "Sum"
  threshold                 = var.elb_low_request_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.elb_low_request_count_treat_missing_data
  tags                      = var.tags
}
