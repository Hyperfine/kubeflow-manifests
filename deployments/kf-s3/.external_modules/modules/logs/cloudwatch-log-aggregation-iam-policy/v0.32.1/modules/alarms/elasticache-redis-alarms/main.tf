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
# CREATE CLOUDWATCH ALARMS FOR AN ELASTICACHE CLUSTER RUNNING REDIS
# For detailed explanations of these metrics, see:
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/elasticache-metricscollected.html
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "elasticache_high_cpu_utilization" {
  count             = var.create_resources ? var.num_cluster_ids : 0
  alarm_name        = "${var.cache_cluster_ids[count.index]}-${var.cache_node_id}-high-cpu-utilization"
  alarm_description = "An alarm that goes off if the CPU usage is too high in ElastiCache cluster ${var.cache_cluster_ids[count.index]}"
  namespace         = "AWS/ElastiCache"
  metric_name       = "CPUUtilization"

  dimensions = {
    CacheClusterId = var.cache_cluster_ids[count.index]
    CacheNodeId    = var.cache_node_id
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

resource "aws_cloudwatch_metric_alarm" "elasticache_high_engine_cpu_utilization" {
  count             = var.create_resources ? var.num_cluster_ids : 0
  alarm_name        = "${var.cache_cluster_ids[count.index]}-${var.cache_node_id}-high-engine-cpu-utilization"
  alarm_description = "An alarm that goes off if the Engine CPU usage is too high in ElastiCache cluster ${var.cache_cluster_ids[count.index]}"
  namespace         = "AWS/ElastiCache"
  metric_name       = "EngineCPUUtilization"

  dimensions = {
    CacheClusterId = var.cache_cluster_ids[count.index]
    CacheNodeId    = var.cache_node_id
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_engine_cpu_utilization_evaluation_periods
  period                    = var.high_engine_cpu_utilization_period
  statistic                 = var.high_engine_cpu_utilization_statistic
  threshold                 = var.high_engine_cpu_utilization_threshold
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "elasticache_low_memory_available" {
  count             = var.create_resources ? var.num_cluster_ids : 0
  alarm_name        = "${var.cache_cluster_ids[count.index]}-${var.cache_node_id}-low-memory-available"
  alarm_description = "An alarm that goes off if the ElastiCache cluster ${var.cache_cluster_ids[count.index]} is running low on free memory."
  namespace         = "AWS/ElastiCache"
  metric_name       = "FreeableMemory"

  dimensions = {
    CacheClusterId = var.cache_cluster_ids[count.index]
    CacheNodeId    = var.cache_node_id
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

resource "aws_cloudwatch_metric_alarm" "elasticache_database_memory_usage_percentage" {
  count             = var.create_resources && var.monitor_database_memory_usage_percentage ? var.num_cluster_ids : 0
  alarm_name        = "${var.cache_cluster_ids[count.index]}-${var.cache_node_id}-database-memory-usage-percentage"
  alarm_description = "An alarm that goes off if the ElastiCache cluster ${var.cache_cluster_ids[count.index]} database memory usage percentage is too high."
  namespace         = "AWS/ElastiCache"
  metric_name       = "DatabaseMemoryUsagePercentage"

  dimensions = {
    CacheClusterId = var.cache_cluster_ids[count.index]
    CacheNodeId    = var.cache_node_id
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.database_memory_usage_percentage_evaluation_periods
  period                    = var.database_memory_usage_percentage_period
  statistic                 = var.database_memory_usage_percentage_statistic
  threshold                 = var.database_memory_usage_percentage_threshold
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "elasticache_swap_usage" {
  count             = var.create_resources ? var.num_cluster_ids : 0
  alarm_name        = "${var.cache_cluster_ids[count.index]}-${var.cache_node_id}-swap-usage"
  alarm_description = "An alarm that goes off if the ElastiCache cluster ${var.cache_cluster_ids[count.index]} swap usage is too high."
  namespace         = "AWS/ElastiCache"
  metric_name       = "SwapUsage"

  dimensions = {
    CacheClusterId = var.cache_cluster_ids[count.index]
    CacheNodeId    = var.cache_node_id
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.swap_usage_evaluation_periods
  period                    = var.swap_usage_period
  statistic                 = var.swap_usage_statistic
  threshold                 = var.swap_usage_threshold
  unit                      = "Bytes"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "elasticache_curr_connections" {
  count             = var.create_resources && var.monitor_curr_connections ? var.num_cluster_ids : 0
  alarm_name        = "${var.cache_cluster_ids[count.index]}-${var.cache_node_id}-curr-connections"
  alarm_description = "An alarm that goes off if the ElastiCache cluster ${var.cache_cluster_ids[count.index]} current connections is too high."
  namespace         = "AWS/ElastiCache"
  metric_name       = "CurrConnections"

  dimensions = {
    CacheClusterId = var.cache_cluster_ids[count.index]
    CacheNodeId    = var.cache_node_id
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.curr_connections_evaluation_periods
  period                    = var.curr_connections_period
  statistic                 = var.curr_connections_statistic
  threshold                 = var.curr_connections_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "elasticache_replication_lag" {
  count             = var.create_resources && var.monitor_replication_lag ? var.num_cluster_ids : 0
  alarm_name        = "${var.cache_cluster_ids[count.index]}-${var.cache_node_id}-replication-lag"
  alarm_description = "An alarm that goes off if the ElastiCache cluster ${var.cache_cluster_ids[count.index]} replication lag is too high."
  namespace         = "AWS/ElastiCache"
  metric_name       = "ReplicationLag"

  dimensions = {
    CacheClusterId = var.cache_cluster_ids[count.index]
    CacheNodeId    = var.cache_node_id
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.replication_lag_evaluation_periods
  period                    = var.replication_lag_period
  statistic                 = var.replication_lag_statistic
  threshold                 = var.replication_lag_threshold
  unit                      = "Milliseconds"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}
