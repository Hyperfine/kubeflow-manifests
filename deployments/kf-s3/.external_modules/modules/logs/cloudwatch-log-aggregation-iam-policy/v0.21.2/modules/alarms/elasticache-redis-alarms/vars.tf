# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the ElastiCache alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "cache_cluster_ids" {
  description = "The IDs of the ElastiCache clusters. With Redis, each cluster contains just one node, and a replication group may contain multiple clusters."
  type        = list(string)
}

variable "num_cluster_ids" {
  description = "The number of ids in var.cache_cluster_ids. We should be able to compute this automatically, but can't due to a Terraform bug: https://github.com/hashicorp/terraform/issues/3888"
  type        = number
}

variable "cache_node_id" {
  description = "The id of the nodes in the ElastiCache clusters. With Redis, each cluster contains just one node, and all those nodes have the same ID."
  type        = string
}

variable "high_cpu_utilization_threshold" {
  description = "Trigger an alarm if the ElastiCache Node has a CPU utilization percentage above this threshold"
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

variable "low_memory_available_threshold" {
  description = "Trigger an alarm if the amount of free memory, in Bytes, on the ElastiCache Node drops below this threshold"
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
  default     = 1
}

variable "low_memory_available_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Minimum"
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