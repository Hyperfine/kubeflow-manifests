# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE CLOUDWATCH ALARMS FOR AN ELASTICSEARCH CLUSTER
# For detailed explanations of these metrics, see:
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/es-metricscollected.html
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "aws_cloudwatch_metric_alarm" "cluster_status_yellow" {
  count = var.create_resources && ! var.disable_status_yellow_alarm ? 1 : 0

  alarm_name        = "${var.cluster_name}-cluster-status-yellow"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates that the primary shards for all indices are allocated to nodes in a cluster, but the replica shards for at least one index are not."
  namespace         = "AWS/ES"
  metric_name       = "ClusterStatus.yellow"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  statistic                 = "Minimum"
  threshold                 = 0
  evaluation_periods        = 1
  period                    = var.cluster_status_yellow_period
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cluster_status_red" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.cluster_name}-cluster-status-red"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates that the primary and replica shards of at least one index are not allocated to nodes in a cluster."
  namespace         = "AWS/ES"
  metric_name       = "ClusterStatus.red"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  statistic                 = "Minimum"
  threshold                 = 0
  evaluation_periods        = 1
  period                    = var.cluster_status_red_period
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "automated_snapshot_failure" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.cluster_name}-automated-snapshot-failure"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates the cluster has not taken a successful snapshot for at least 36 hours."
  namespace         = "AWS/ES"
  metric_name       = "AutomatedSnapshotFailure"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  statistic                 = "Minimum"
  threshold                 = 0
  evaluation_periods        = var.snapshot_evaluation_period
  period                    = var.snapshot_period
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.cluster_name}-high-cpu-utilization"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates the CPU usage is too high."
  namespace         = "AWS/ES"
  metric_name       = "CPUUtilization"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  threshold                 = var.high_cpu_utilization_threshold
  statistic                 = var.high_cpu_utilization_statistic
  evaluation_periods        = var.high_cpu_utilization_evaluation_periods
  period                    = var.high_cpu_utilization_period
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "low_free_storage_space" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.cluster_name}-low-free-storage-space"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates the cluster is running low on storage space."
  namespace         = "AWS/ES"
  metric_name       = "FreeStorageSpace"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "LessThanThreshold"
  threshold                 = var.low_free_storage_space_threshold
  statistic                 = var.low_free_storage_space_statistic
  evaluation_periods        = var.low_free_storage_space_evaluation_periods
  period                    = var.low_free_storage_space_period
  unit                      = "Megabytes"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_jvm_memory_pressure" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.cluster_name}-high-jvm-memory-pressure"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates the percentage of Java heap space used is too high."
  namespace         = "AWS/ES"
  metric_name       = "JVMMemoryPressure"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  threshold                 = var.high_jvm_memory_pressure_threshold
  statistic                 = var.high_jvm_memory_pressure_statistic
  evaluation_periods        = var.high_jvm_memory_pressure_evaluation_periods
  period                    = var.high_jvm_memory_pressure_period
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  # This metric only exists for t2.xxx instance types
  count             = var.create_resources ? replace(replace(var.instance_type, "/^[^t].*/", "0"), "/^t.*$/", "1") : 0
  alarm_name        = "${var.cluster_name}-low-cpu-credit-balance"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates the number of CPU credits in the cluster is getting low."
  namespace         = "AWS/ES"
  metric_name       = "CPUCreditBalance"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "LessThanThreshold"
  threshold                 = var.low_cpu_credit_balance_threshold
  statistic                 = var.low_cpu_credit_balance_statistic
  evaluation_periods        = var.low_cpu_credit_balance_evaluation_periods
  period                    = var.low_cpu_credit_balance_period
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cluster_index_writes_blocked" {
  count             = var.create_resources ? 1 : 0
  alarm_name        = "${var.cluster_name}-cluster-index-writes-blocked"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates that index writes are blocked."
  namespace         = "AWS/ES"
  metric_name       = "ClusterIndexWritesBlocked"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  threshold                 = 0
  statistic                 = "Minimum"
  evaluation_periods        = var.cluster_index_writes_blocked_evaluation_periods
  period                    = var.cluster_index_writes_blocked_period
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "master_cpu_utilization" {
  count             = var.create_resources && var.monitor_master_nodes ? 1 : 0
  alarm_name        = "${var.cluster_name}-master-cpu-utilization"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates that master CPU utilization is too high."
  namespace         = "AWS/ES"
  metric_name       = "MasterCPUUtilization"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  threshold                 = var.master_cpu_utilization_threshold
  statistic                 = var.master_cpu_utilization_statistic
  evaluation_periods        = var.master_cpu_utilization_evaluation_periods
  period                    = var.master_cpu_utilization_period
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "master_jvm_memory_pressure" {
  count             = var.create_resources && var.monitor_master_nodes ? 1 : 0
  alarm_name        = "${var.cluster_name}-master-jvm-memory-pressure"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates that master memory pressure is too high."
  namespace         = "AWS/ES"
  metric_name       = "MasterJVMMemoryPressure"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  threshold                 = var.master_jvm_memory_pressure_threshold
  statistic                 = var.master_jvm_memory_pressure_statistic
  evaluation_periods        = var.master_jvm_memory_pressure_evaluation_periods
  period                    = var.master_jvm_memory_pressure_period
  unit                      = "Percent"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "kms_key_error" {
  count             = var.create_resources && var.monitor_kms_key ? 1 : 0
  alarm_name        = "${var.cluster_name}-kms-key-error"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates that the KMS encryption key used to encrypt data at rest is disabled."
  namespace         = "AWS/ES"
  metric_name       = "KMSKeyError"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  threshold                 = 0
  statistic                 = "Minimum"
  evaluation_periods        = var.kms_key_error_evaluation_periods
  period                    = var.kms_key_error_period
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "kms_key_inaccessible" {
  count             = var.create_resources && var.monitor_kms_key ? 1 : 0
  alarm_name        = "${var.cluster_name}-kms-key-inaccessible"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates that the KMS encryption key used to encrypt data at rest deleted or has revoked its grants to Amazon ES."
  namespace         = "AWS/ES"
  metric_name       = "KMSKeyInaccessible"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "GreaterThanThreshold"
  threshold                 = 0
  statistic                 = "Minimum"
  evaluation_periods        = var.kms_key_inaccessible_evaluation_periods
  period                    = var.kms_key_inaccessible_period
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}

resource "aws_cloudwatch_metric_alarm" "node_count" {
  count             = ! var.create_resources || var.instance_count == null ? 0 : 1
  alarm_name        = "${var.cluster_name}-node-count"
  alarm_description = "An alarm for the Elasticsearch cluster ${var.cluster_name} that indicates that nodes are missing."
  namespace         = "AWS/ES"
  metric_name       = "Nodes"

  dimensions = {
    DomainName = var.cluster_name
    ClientId   = var.aws_account_id
  }

  comparison_operator       = "LessThanThreshold"
  threshold                 = var.instance_count
  statistic                 = "Maximum"
  evaluation_periods        = var.node_count_evaluation_periods
  period                    = var.node_count_period
  unit                      = "Count"
  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = var.alarm_sns_topic_arns
  tags                      = var.tags
}
