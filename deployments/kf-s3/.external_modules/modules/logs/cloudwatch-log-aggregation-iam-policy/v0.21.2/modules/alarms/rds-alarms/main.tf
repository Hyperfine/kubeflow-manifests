# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE CLOUDWATCH ALARMS FOR RDS METRICS
# For detailed explanations of these metrics, see:
# http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/rds-metricscollected.html
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu_utilization" {
  count             = var.create_resources ? var.num_rds_instance_ids : 0
  alarm_name        = "${var.rds_instance_ids[count.index]}-high-cpu-utilization"
  alarm_description = "An alarm that goes off if the CPU usage is too high on the RDS instance ${var.rds_instance_ids[count.index]}"
  namespace         = "AWS/RDS"
  metric_name       = "CPUUtilization"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_cpu_utilization_evaluation_periods
  period                    = var.high_cpu_utilization_period
  datapoints_to_alarm       = var.high_cpu_utilization_datapoints_to_alarm == null ? var.high_cpu_utilization_evaluation_periods : var.high_cpu_utilization_datapoints_to_alarm
  statistic                 = var.high_cpu_utilization_statistic
  threshold                 = var.high_cpu_utilization_threshold
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.high_cpu_utilization_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_low_memory_available" {
  count             = var.create_resources ? var.num_rds_instance_ids : 0
  alarm_name        = "${var.rds_instance_ids[count.index]}-low-memory-available"
  alarm_description = "An alarm that goes off if the RDS intance ${var.rds_instance_ids[count.index]} is running low on free memory."
  namespace         = "AWS/RDS"
  metric_name       = "FreeableMemory"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.low_memory_available_evaluation_periods
  period                    = var.low_memory_available_period
  datapoints_to_alarm       = var.low_memory_available_datapoints_to_alarm == null ? var.low_memory_available_evaluation_periods : var.low_memory_available_datapoints_to_alarm
  statistic                 = var.low_memory_available_statistic
  threshold                 = var.low_memory_available_threshold
  unit                      = "Bytes"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.low_memory_available_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_disk_space_available" {
  count             = var.create_resources ? var.num_rds_instance_ids : 0
  alarm_name        = "${var.rds_instance_ids[count.index]}-low-disk-space-available"
  alarm_description = "An alarm that goes off if the DB instance ${var.rds_instance_ids[count.index]} is running low on disk space."
  namespace         = "AWS/RDS"
  metric_name       = var.is_aurora ? "FreeLocalStorage" : "FreeStorageSpace"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.low_disk_space_available_evaluation_periods
  period                    = var.low_disk_space_available_period
  datapoints_to_alarm       = var.disk_space_available_datapoints_to_alarm == null ? var.low_disk_space_available_evaluation_periods : var.disk_space_available_datapoints_to_alarm
  statistic                 = var.low_disk_space_available_statistic
  threshold                 = var.low_disk_space_available_threshold
  unit                      = "Bytes"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.disk_space_available_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_too_many_db_connections" {
  count             = var.create_resources ? var.num_rds_instance_ids : 0
  alarm_name        = "${var.rds_instance_ids[count.index]}-too-many-db-connections"
  alarm_description = "An alarm that goes off if the RDS intance ${var.rds_instance_ids[count.index]} has too many DB connections in use."
  namespace         = "AWS/RDS"
  metric_name       = "DatabaseConnections"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.too_many_db_connections_evaluation_periods
  period                    = var.too_many_db_connections_period
  datapoints_to_alarm       = var.too_many_db_connections_datapoints_to_alarm == null ? var.too_many_db_connections_evaluation_periods : var.too_many_db_connections_datapoints_to_alarm
  statistic                 = var.too_many_db_connections_statistic
  threshold                 = var.too_many_db_connections_threshold
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.too_many_db_connections_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_replication_error" {
  count             = var.create_resources ? var.num_rds_instance_ids : 0
  alarm_name        = "${var.rds_instance_ids[count.index]}-replication-error"
  alarm_description = "An alarm that goes off if the DB instance ${var.rds_instance_ids[count.index]} has a replication error."
  namespace         = "AWS/RDS"
  metric_name       = var.is_aurora ? "AuroraBinlogReplicaLag" : "ReplicaLag"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = var.replication_error_evaluation_periods
  period                    = var.replication_error_period
  datapoints_to_alarm       = var.replication_error_datapoints_to_alarm == null ? var.replication_error_evaluation_periods : var.replication_error_datapoints_to_alarm
  statistic                 = "Average"
  threshold                 = "-1"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.replication_error_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_high_replica_lag" {
  count             = var.create_resources ? var.num_rds_instance_ids : 0
  alarm_name        = "${var.rds_instance_ids[count.index]}-high-replica-lag"
  alarm_description = "An alarm that goes off if the replica lag gets too high on RDS instance ${var.rds_instance_ids[count.index]}."
  namespace         = "AWS/RDS"
  metric_name       = var.is_aurora ? "AuroraBinlogReplicaLag" : "ReplicaLag"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_replica_lag_evaluation_periods
  period                    = var.high_replica_lag_period
  datapoints_to_alarm       = var.high_replica_lag_datapoints_to_alarm == null ? var.high_replica_lag_evaluation_periods : var.high_replica_lag_datapoints_to_alarm
  statistic                 = var.high_replica_lag_statistic
  threshold                 = var.high_replica_lag_threshold
  unit                      = "Seconds"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.high_replica_lag_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_high_read_latency" {
  # Only create this alarm if var.enable_perf_alarms is set to true.
  count             = var.create_resources && var.enable_perf_alarms ? var.num_rds_instance_ids : 0
  alarm_name        = "${var.rds_instance_ids[count.index]}-high-read-latency"
  alarm_description = "An alarm that goes off if the read latency (average amount of time taken per disk I/O operation) gets too high on RDS instance ${var.rds_instance_ids[count.index]}"
  namespace         = "AWS/RDS"
  metric_name       = "ReadLatency"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_read_latency_evaluation_periods
  period                    = var.high_read_latency_period
  datapoints_to_alarm       = var.high_read_latency_datapoints_to_alarm == null ? var.high_read_latency_evaluation_periods : var.high_read_latency_datapoints_to_alarm
  statistic                 = var.high_read_latency_statistic
  threshold                 = var.high_read_latency_threshold
  unit                      = "Seconds"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.high_read_latency_treat_missing_data
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_high_write_latency" {
  # Only create this alarm if var.enable_perf_alarms is set to true.
  count             = var.create_resources && var.enable_perf_alarms ? var.num_rds_instance_ids : 0
  alarm_name        = "${var.rds_instance_ids[count.index]}-high-write-latency"
  alarm_description = "An alarm that goes off if the write latency (average amount of time taken per disk I/O operation) gets too high on RDS instance ${var.rds_instance_ids[count.index]}"
  namespace         = "AWS/RDS"
  metric_name       = "WriteLatency"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[count.index]
  }

  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.high_write_latency_evaluation_periods
  period                    = var.high_read_latency_period
  datapoints_to_alarm       = var.high_write_latency_datapoints_to_alarm == null ? var.high_write_latency_evaluation_periods : var.high_write_latency_datapoints_to_alarm
  statistic                 = var.high_write_latency_statistic
  threshold                 = var.high_write_latency_threshold
  unit                      = "Seconds"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  treat_missing_data        = var.high_write_latency_treat_missing_data
  tags                      = var.tags
}
