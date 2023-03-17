# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE CLOUDWATCH ALARMS FOR ALB METRICS
# For detailed explanations of these metrics, see:
# http://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/elb-metricscollected.html#load-balancer-metrics-alb
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


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
# CREATE ALARMS
# ----------------------------------------------------------------------------------------------------------------------

# ActiveConnectionCount
# - The most useful statistic is Sum.
resource "aws_cloudwatch_metric_alarm" "alb_high_active_connection_count" {
  # Only create this alarm if var.alb_high_active_connection_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_high_active_connection_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-high-active-connection-count"
  alarm_description = "An alarm that goes off if the total number of concurrent TCP connections active from clients to the ALB ${var.alb_name} and from the ALB to targets exceeds the threshold."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "ActiveConnectionCount"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alb_high_active_connection_count_evaluation_periods
  period                    = var.alb_high_active_connection_count_period
  datapoints_to_alarm       = var.alb_high_active_connection_count_datapoints_to_alarm == null ? var.alb_high_active_connection_count_evaluation_periods : var.alb_high_active_connection_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_high_active_connection_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_high_active_connection_count_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_low_active_connection_count" {
  # Only create this alarm if var.alb_low_active_connection_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_low_active_connection_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-low-active-connection-count"
  alarm_description = "An alarm that goes off if the total number of concurrent TCP connections active from clients to the ALB ${var.alb_name} and from the ALB to targets boes below the threshold."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "ActiveConnectionCount"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.alb_low_active_connection_count_evaluation_periods
  period                    = var.alb_low_active_connection_count_period
  datapoints_to_alarm       = var.alb_low_active_connection_count_datapoints_to_alarm == null ? var.alb_low_active_connection_count_evaluation_periods : var.alb_low_active_connection_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_low_active_connection_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_low_active_connection_count_treat_missing_data
  tags                      = var.tags
}

# ClientTLSNegotiationErrorCount
# - The most useful statistic is Sum.
resource "aws_cloudwatch_metric_alarm" "alb_high_client_tls_negotiation_error_count" {
  # Only create this alarm if var.alb_high_client_tls_negotiation_error_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_high_client_tls_negotiation_error_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-high-client-tls-negotiation-error-count"
  alarm_description = "An alarm that goes off if the number of TLS connections initiated by the client that did not establish a session with the ALB ${var.alb_name} exceeds the threshold. Possible causes include a mismatch of ciphers or protocols."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "ClientTLSNegotiationErrorCount"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alb_high_client_tls_negotiation_error_count_evaluation_periods
  period                    = var.alb_high_client_tls_negotiation_error_count_period
  datapoints_to_alarm       = var.alb_high_client_tls_negotiation_error_count_datapoints_to_alarm == null ? var.alb_high_client_tls_negotiation_error_count_evaluation_periods : var.alb_high_client_tls_negotiation_error_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_high_client_tls_negotiation_error_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_high_client_tls_negotiation_error_count_treat_missing_data
  tags                      = var.tags
}

# HTTPCode_ELB_4XX_Count:  Client errors
# - The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1.
resource "aws_cloudwatch_metric_alarm" "alb_high_http_code_4xx_count" {
  # Only create this alarm if var.alb_high_http_code_4xx_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_high_http_code_4xx_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-high-http-code-4xx-count"
  alarm_description = "An alarm that goes off if the number of HTTP 4XX client error codes that originate from the ALB ${var.alb_name} exceeds the threshold. These requests have not been received by the target. This count does not include any response codes generated by the targets."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "HTTPCode_ELB_4XX_Count"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alb_high_http_code_4xx_count_evaluation_periods
  period                    = var.alb_high_http_code_4xx_count_period
  datapoints_to_alarm       = var.alb_high_http_code_4xx_count_datapoints_to_alarm == null ? var.alb_high_http_code_4xx_count_evaluation_periods : var.alb_high_http_code_4xx_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_high_http_code_4xx_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_high_http_code_4xx_count_treat_missing_data
  tags                      = var.tags
}

# HTTPCode_ELB_5XX_Count
# - The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1.
resource "aws_cloudwatch_metric_alarm" "alb_high_http_code_5xx_count" {
  # Only create this alarm if var.alb_high_http_code_5xx_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_high_http_code_5xx_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-high-http-code-5xx-count"
  alarm_description = "An alarm that goes off if the number of HTTP 5XX client error codes that originate from the ALB ${var.alb_name} exceeds the threshold. These requests have not been received by the target. This count does not include any response codes generated by the targets."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "HTTPCode_ELB_5XX_Count"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alb_high_http_code_5xx_count_evaluation_periods
  period                    = var.alb_high_http_code_5xx_count_period
  datapoints_to_alarm       = var.alb_high_http_code_5xx_count_datapoints_to_alarm == null ? var.alb_high_http_code_5xx_count_evaluation_periods : var.alb_high_http_code_5xx_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_high_http_code_5xx_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_high_http_code_5xx_count_treat_missing_data
  tags                      = var.tags
}

# NewConnectionCount:
# - The most useful statistic is Sum.
resource "aws_cloudwatch_metric_alarm" "alb_high_new_connection_count" {
  # Only create this alarm if var.alb_high_new_connection_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_high_new_connection_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-high-new-connection-count"
  alarm_description = "An alarm that goes off if the the total number of new TCP connections established from clients to the ALB ${var.alb_name} and from the ALB to targets exceeds the threshold."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "NewConnectionCount"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alb_high_new_connection_count_evaluation_periods
  period                    = var.alb_high_new_connection_count_period
  datapoints_to_alarm       = var.alb_high_new_connection_count_datapoints_to_alarm == null ? var.alb_high_new_connection_count_evaluation_periods : var.alb_high_new_connection_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_high_new_connection_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_high_new_connection_count_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_low_new_connection_count" {
  # Only create this alarm if var.alb_low_new_connection_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_low_new_connection_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-low-new-connection-count"
  alarm_description = "An alarm that goes off if the the total number of new TCP connections established from clients to the ALB ${var.alb_name} and from the ALB to targets goes below the threshold."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "NewConnectionCount"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.alb_low_new_connection_count_evaluation_periods
  period                    = var.alb_low_new_connection_count_period
  datapoints_to_alarm       = var.alb_low_new_connection_count_datapoints_to_alarm == null ? var.alb_low_new_connection_count_evaluation_periods : var.alb_low_new_connection_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_low_new_connection_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_low_new_connection_count_treat_missing_data
  tags                      = var.tags
}

# RejectedConnectionCount:
# - The most useful statistic is Sum.
resource "aws_cloudwatch_metric_alarm" "alb_high_rejected_connection_count" {
  # Only create this alarm if var.alb_high_rejected_connection_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_high_rejected_connection_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-high-rejected-connection-count"
  alarm_description = "An alarm that goes off if the number of connections that were rejected because the ALB ${var.alb_name} reached its maximum number of connections exceeds the threshold."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "RejectedConnectionCount"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alb_high_rejected_connection_count_evaluation_periods
  period                    = var.alb_high_rejected_connection_count_period
  datapoints_to_alarm       = var.alb_high_rejected_connection_count_datapoints_to_alarm == null ? var.alb_high_rejected_connection_count_evaluation_periods : var.alb_high_rejected_connection_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_high_rejected_connection_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_high_rejected_connection_count_treat_missing_data
  tags                      = var.tags
}

# RequestCount:
# - The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1.
resource "aws_cloudwatch_metric_alarm" "alb_high_request_count" {
  # Only create this alarm if var.alb_high_request_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_high_request_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-high-request-count"
  alarm_description = "An alarm that goes off if the number of requests received by the ALB ${var.alb_name} exceeds the threshold."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "RequestCount"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alb_high_request_count_evaluation_periods
  period                    = var.alb_high_request_count_period
  datapoints_to_alarm       = var.alb_high_request_count_datapoints_to_alarm == null ? var.alb_high_request_count_evaluation_periods : var.alb_high_request_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_high_request_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_high_request_count_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_low_request_count" {
  # Only create this alarm if var.alb_low_request_count_threshold is greater than 0.
  count             = var.create_resources && var.alb_low_request_count_threshold > 0 ? 1 : 0
  alarm_name        = "${var.alb_name}-low_request_count"
  alarm_description = "An alarm that goes off if the number of requests received by the ALB ${var.alb_name} goes below the threshold."
  namespace         = "AWS/ApplicationELB"
  metric_name       = "RequestCount"
  dimensions = {
    LoadBalancer = local.load_balancer_dimension_value
  }
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.alb_low_request_count_evaluation_periods
  period                    = var.alb_low_request_count_period
  datapoints_to_alarm       = var.alb_low_request_count_datapoints_to_alarm == null ? var.alb_low_request_count_evaluation_periods : var.alb_low_request_count_datapoints_to_alarm
  statistic                 = "Sum"
  threshold                 = var.alb_low_request_count_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.alb_low_request_count_treat_missing_data
  tags                      = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# CONVENIENCE VARIABLES
# This section wraps complex Terraform expressions in a nicer construct.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Per https://goo.gl/8ih8rP, for the "LoadBalancer" dimension on ALB Metrics, we need to extract "app/ecs-cluster-stage/518523gede75d9f3"
  # from an ALB ARN like "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/ecs-cluster-stage/518523gede75d9f3"
  load_balancer_dimension_value = replace(split(":", var.alb_arn)[5], "loadbalancer/", "")
}
