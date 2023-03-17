# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the ECS Service alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "ecs_service_name" {
  description = "The name of the ECS Service"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS Cluster the ECS Service is in"
  type        = string
}

variable "high_cpu_utilization_threshold" {
  description = "Trigger an alarm if the ECS Service has a CPU utilization percentage above this threshold"
  type        = number
  default     = 90
}

variable "high_cpu_utilization_period" {
  description = "The period, in seconds, over which to measure the CPU utilization percentage. Amazon ECS sends metrics to CloudWatch every 60 seconds, so 60 seconds is the minimum."
  type        = number
  default     = 60
}

variable "high_cpu_utilization_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "high_cpu_utilization_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 2
}

variable "high_cpu_utilization_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "high_memory_utilization_threshold" {
  description = "Trigger an alarm if the ECS Service has a memory utilization percentage above this threshold"
  type        = number
  default     = 90
}

variable "high_memory_utilization_period" {
  description = "The period, in seconds, over which to measure the memory utilization percentage. Amazon ECS sends metrics to CloudWatch every 60 seconds, so 60 seconds is the minimum."
  type        = number
  default     = 60
}

variable "high_memory_utilization_datapoints_to_alarm" {
  description = "The number of datapoints in CloudWatch Metric statistic, which triggers the alarm. Setting this as null (the default) will make it equal to the evaluation period"
  type        = number
  default     = null
}

variable "high_memory_utilization_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 2
}

variable "high_memory_utilization_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Average"
}

variable "ecs_service_high_memory_utilization_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type        = string
  default     = "missing"
}

variable "ecs_service_high_cpu_utilization_treat_missing_data" {
  description = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
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