# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the RDS alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "rds_instance_ids" {
  description = "The list of ids of the RDS instances"
  type        = list(string)
}

variable "num_rds_instance_ids" {
  description = "The number of ids in var.rds_instance_ids. We should be able to compute this automatically, but can't due to a Terraform bug: https://github.com/hashicorp/terraform/issues/3888"
  type        = number
}

variable "is_aurora" {
  description = "A boolean that indicates whether this RDS cluster is running Aurora. If it is, Aurora automatically expands disk space as necessary, so we do not add the disk space alarm."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARM DEFAULTS
# Each CloudWatch Alarm defines the following properties:
# ---------------------------------------------------------------------------------------------------------------------

# CPU utilization - High CPU utilization threshold

variable "high_cpu_utilization_threshold" {
  description = "Trigger an alarm if the DB instance has a CPU utilization percentage above this threshold"
  type        = number
  default     = 90
}

variable "high_cpu_utilization_period" {
  description = "The period, in seconds, over which to measure the CPU utilization percentage"
  type        = number
  default     = 60
}

variable "high_cpu_utilization_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 3
}

variable "high_cpu_utilization_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "high_cpu_utilization_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "high_cpu_utilization_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

# Memory - Low memory available threshold

variable "low_memory_available_threshold" {
  description = "Trigger an alarm if the amount of free memory, in Bytes, on the DB instance drops below this threshold"
  type        = number

  # Default is 100MB (100 million bytes)
  default = 100000000
}

variable "low_memory_available_period" {
  description = "The period, in seconds, over which to measure the available free memory"
  type        = number
  default     = 60
}

variable "low_memory_available_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 3
}

variable "low_memory_available_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Minimum"
}

variable "low_memory_available_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "low_memory_available_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

# Disk - Low disk space threshold

variable "low_disk_space_available_threshold" {
  description = "Trigger an alarm if the amount of disk space, in Bytes, on the DB instance drops below this threshold"
  type        = number

  # Default is 1GB (1 billion bytes)
  default = 1000000000
}

variable "low_disk_space_available_period" {
  description = "The period, in seconds, over which to measure the available free disk space"
  type        = number
  default     = 60
}

variable "low_disk_space_available_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 3
}

variable "low_disk_space_available_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Minimum"
}

variable "disk_space_available_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = string
  default     = null
}

variable "disk_space_available_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

# DB - DB high connections threshold

variable "too_many_db_connections_threshold" {
  description = "Trigger an alarm if the number of connections to the DB instance goes above this threshold"
  type        = number
  # The max number of connections allowed by RDS depends a) the type of DB, b) the DB instance type, and c) the
  # use case, and it can vary from ~30 all the way up to 5,000, so we cannot pick a reasonable default here and require
  # the user to always specify a value.
}

variable "too_many_db_connections_period" {
  description = "The period, in seconds, over which to measure the number of DB connections"
  type        = number
  default     = 60
}

variable "too_many_db_connections_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 3
}

variable "too_many_db_connections_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Maximum"
}

variable "too_many_db_connections_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as empty string (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "too_many_db_connections_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

# Replication - Replication Error threshold

variable "replication_error_period" {
  description = "The period, in seconds, over which to measure the replica lag metric."
  type        = number
  default     = 60
}

variable "replication_error_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 3
}

variable "replication_error_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as empty string (the default) will make it equal to the evaluation period."
  type        = number
  default     = null
}

variable "replication_error_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

# Replication - High replica lag threshold

variable "high_replica_lag_threshold" {
  description = "Trigger an alarm if the DB instance replica lag, in seconds, is above this threshold"
  type        = number
  default     = 300
}

variable "high_replica_lag_period" {
  description = "The period, in seconds, over which to measure the replica lag metric."
  type        = number
  default     = 60
}

variable "high_replica_lag_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 5
}

variable "high_replica_lag_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "high_replica_lag_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as empty string (the default) will make it equal to the evaluation period."
  type        = number
  default     = null
}

variable "high_replica_lag_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

# Latency - High read latency threshold

variable "enable_perf_alarms" {
  description = "Set to true to enable alarms related to performance, such as read and write latency alarms. Set to false to disable those alarms if you aren't sure what would be reasonable perf numbers for your RDS set up or if those numbers are too unpredictable."
  type        = bool
  default     = true
}

variable "high_read_latency_threshold" {
  description = "Trigger an alarm if the DB instance read latency (average amount of time taken per disk I/O operation), in seconds, is above this threshold"
  type        = number
  default     = 5
}

variable "high_read_latency_period" {
  description = "The period, in seconds, over which to measure the read latency"
  type        = number
  default     = 60
}

variable "high_read_latency_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 3
}

variable "high_read_latency_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "high_read_latency_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as empty string (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "high_read_latency_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

# Latency - High write latency threshold

variable "high_write_latency_threshold" {
  description = "Trigger an alarm if the DB instance write latency (average amount of time taken per disk I/O operation), in seconds, is above this threshold"
  type        = number
  default     = 5
}

variable "high_write_latency_period" {
  description = "The period, in seconds, over which to measure the write latency"
  type        = number
  default     = 60
}

variable "high_write_latency_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 3
}

variable "high_write_latency_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "high_write_latency_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as empty string (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "high_write_latency_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "tags" {
  description = "A map of tags to apply to the metric alarm. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}