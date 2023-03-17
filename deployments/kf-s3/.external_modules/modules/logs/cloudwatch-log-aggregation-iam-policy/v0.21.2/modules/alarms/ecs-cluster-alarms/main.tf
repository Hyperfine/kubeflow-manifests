# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE CLOUDWATCH ALARMS FOR AN ECS CLUSTER
# For detailed explanations of these metrics, see:
# http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/elb-cloudwatch-metrics.html
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ecs_cluster_high_cpu_utilization" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.ecs_cluster_name}-high-cpu-utilization"
  alarm_description = "An alarm that goes off if the CPU usage is too high in the ECS Cluster ${var.ecs_cluster_name}."
  namespace         = "AWS/ECS"
  metric_name       = "CPUUtilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_cpu_utilization_evaluation_periods
  period                    = var.high_cpu_utilization_period
  statistic                 = var.high_cpu_utilization_statistic
  threshold                 = var.high_cpu_utilization_threshold
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.ecs_cluster_high_cpu_utilization_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_cluster_high_memory_utilization" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.ecs_cluster_name}-high-memory-utilization"
  alarm_description = "An alarm that goes off if the memory usage is too high in the ECS Cluster ${var.ecs_cluster_name}."
  namespace         = "AWS/ECS"
  metric_name       = "MemoryUtilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_memory_utilization_evaluation_periods
  period                    = var.high_memory_utilization_period
  statistic                 = var.high_memory_utilization_statistic
  threshold                 = var.high_memory_utilization_threshold
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.ecs_cluster_high_memory_utilization_treat_missing_data
  tags                      = var.tags
}
