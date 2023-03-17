# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE CLOUDWATCH ALARMS FOR AN ELASTICACHE CLUSTER RUNNING MEMCACHED
# For detailed explanations of these metrics, see:
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/elasticache-metricscollected.html
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "elasticache_high_cpu_utilization" {
  count             = var.create_resources ? var.num_cache_node_ids : 0
  alarm_name        = "${var.cache_cluster_id}-${var.cache_node_ids[count.index]}-high-cpu-utilization"
  alarm_description = "An alarm that goes off if the CPU usage is too high on the Elasticache node ${var.cache_node_ids[count.index]} in cluster ${var.cache_cluster_id}"
  namespace         = "AWS/ElastiCache"
  metric_name       = "CPUUtilization"

  dimensions = {
    CacheClusterId = var.cache_cluster_id
    CacheNodeId    = var.cache_node_ids[count.index]
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
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "elasticache_low_memory_available" {
  count             = var.create_resources ? var.num_cache_node_ids : 0
  alarm_name        = "${var.cache_cluster_id}-${var.cache_node_ids[count.index]}-low-memory-available"
  alarm_description = "An alarm that goes off if the ElastiCache Node ${var.cache_node_ids[count.index]} in cluster ${var.cache_cluster_id} is running low on free memory."
  namespace         = "AWS/ElastiCache"
  metric_name       = "FreeableMemory"

  dimensions = {
    CacheClusterId = var.cache_cluster_id
    CacheNodeId    = var.cache_node_ids[count.index]
  }

  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.low_memory_available_evaluation_periods
  period                    = var.low_memory_available_period
  statistic                 = var.low_memory_available_statistic
  threshold                 = var.low_memory_available_threshold
  unit                      = "Bytes"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}
