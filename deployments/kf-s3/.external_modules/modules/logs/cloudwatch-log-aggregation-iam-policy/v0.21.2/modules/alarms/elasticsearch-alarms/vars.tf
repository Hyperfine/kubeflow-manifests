# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the Elasticsearch alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "cluster_name" {
  description = "The name of the Elasticsearch cluster (AKA the domain)"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS account the elasticsearch cluster belongs to"
  type        = string
}

variable "instance_type" {
  description = "The type of instances deployed in the Elasticsearch cluster (e.g. r3.large.elasticsearch)"
  type        = string
}

variable "disable_status_yellow_alarm" {
  description = "Variable determining if the status yellow alarm will be created. This can be useful for cluster intentionally created with one instance."
  type        = bool
  default     = false
}

variable "cluster_status_yellow_period" {
  description = "The maximum amount of time, in seconds, during which the cluster can be in yellow status before triggering an alarm"
  type        = number
  default     = 300
}

variable "cluster_status_red_period" {
  description = "The maximum amount of time, in seconds, during which the cluster can be in red status before triggering an alarm"
  type        = number
  default     = 300
}

variable "snapshot_period" {
  description = "The maximum amount of time, in seconds, during with the AutomatedSnapshotFailure can be in red status before triggering an alarm"
  type        = number
  default     = 60
}

variable "snapshot_evaluation_period" {
  description = "The number of periods over which data is compared to the specified threshold"
  type        = number
  default     = 1
}

variable "high_cpu_utilization_threshold" {
  description = "Trigger an alarm if the Elasticsearch cluster has a CPU utilization percentage above this threshold"
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
  default     = 1
}

variable "high_cpu_utilization_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "low_free_storage_space_threshold" {
  description = "Trigger an alarm if the amount of free storage space, in Megabytes, on the Elasticsearch cluster drops below this threshold"
  type        = number
  default     = 1024
}

variable "low_free_storage_space_period" {
  description = "The period, in seconds, over which to measure the available free storage space"
  type        = number
  default     = 60
}

variable "low_free_storage_space_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "low_free_storage_space_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Minimum"
}

variable "high_jvm_memory_pressure_threshold" {
  description = "Trigger an alarm if the JVM heap usage percentage goes above this threshold"
  type        = number
  default     = 90
}

variable "high_jvm_memory_pressure_period" {
  description = "The period, in seconds, over which to measure the JVM heap usage percentage"
  type        = number
  default     = 60
}

variable "high_jvm_memory_pressure_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "high_jvm_memory_pressure_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "low_cpu_credit_balance_threshold" {
  description = "Trigger an alarm if the CPU credit balance drops below this threshold. Only used if var.instance_type is t2.xxx."
  type        = number
  default     = 10
}

variable "low_cpu_credit_balance_period" {
  description = "The period, in seconds, over which to measure the CPU credit balance"
  type        = number
  default     = 60
}

variable "low_cpu_credit_balance_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "low_cpu_credit_balance_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Minimum"
}

variable "tags" {
  description = "A map of tags to apply to the metric alarm. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "cluster_index_writes_blocked_period" {
  description = "The maximum amount of time, in seconds, that ClusterIndexWritesBlocked can be in red status before triggering an alarm"
  type        = number
  default     = 300
}

variable "cluster_index_writes_blocked_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold"
  type        = number
  default     = 1
}

variable "monitor_master_nodes" {
  description = "Whether to monitor master node statistics"
  type        = bool
  default     = false
}

variable "master_cpu_utilization_threshold" {
  description = "Trigger an alarm if the Elasticsearch cluster master nodes have a CPU utilization percentage above this threshold"
  type        = number
  default     = 50
}

variable "master_cpu_utilization_period" {
  description = "The period, in seconds, over which to measure the master nodes' CPU utilization"
  type        = number
  default     = 900
}

variable "master_cpu_utilization_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 3
}

variable "master_cpu_utilization_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "master_jvm_memory_pressure_threshold" {
  description = "Trigger an alarm if the Elasticsearch cluster master nodes have a JVM memory pressure percentage above this threshold"
  type        = number
  default     = 80
}

variable "master_jvm_memory_pressure_period" {
  description = "The period, in seconds, over which to measure the master nodes' JVM memory pressure"
  type        = number
  default     = 900
}

variable "master_jvm_memory_pressure_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "master_jvm_memory_pressure_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Maximum"
}

variable "monitor_kms_key" {
  description = "Whether to monitor KMS key statistics"
  type        = bool
  default     = false
}

variable "kms_key_error_period" {
  description = "The maximum amount of time, in seconds, that KMSKeyError can be in red status before triggering an alarm"
  type        = number
  default     = 60
}

variable "kms_key_error_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold"
  type        = number
  default     = 1
}

variable "kms_key_inaccessible_period" {
  description = "The maximum amount of time, in seconds, that KMSKeyInaccessible can be in red status before triggering an alarm"
  type        = number
  default     = 60
}

variable "kms_key_inaccessible_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold"
  type        = number
  default     = 1
}

variable "instance_count" {
  description = "The number of instances in the cluster"
  type        = number
  default     = null
}

variable "node_count_period" {
  description = "The period, in seconds, over which to measure the master nodes' CPU utilization"
  type        = number
  default     = 86400
}

variable "node_count_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}