# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the ELB alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "instance_ids" {
  description = "A list of EC2 Instance ids to monitor"
  type        = list(string)
}

variable "instance_count" {
  description = "The number of instances in var.instance_ids. This should be computable, but a Terraform bug prevents this: https://github.com/hashicorp/terraform/issues/5322."
  type        = number
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARM DEFAULTS
# ---------------------------------------------------------------------------------------------------------------------

variable "high_cpu_utilization_threshold" {
  description = "Trigger an alarm if an EC2 Instance has a CPU utilization percentage above this threshold."
  type        = number
  default     = 90
}

variable "high_cpu_utilization_period" {
  description = "The period, in seconds, over which to measure the CPU utilization percentage."
  type        = number
  default     = 300
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

variable "tags" {
  description = "A map of tags to apply to the metric alarm. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "cpu_metric_namespace" {
  description = "The CloudWatch Namespace where the CPU metrics are reported. Defaults to what is used by EC2."
  type        = string
  default     = "AWS/EC2"
}

variable "cpu_metric_name" {
  description = "The name of the CloudWatch metric that tracks CPU utilization. Defaults to what is used by EC2."
  type        = string
  default     = "CPUUtilization"
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}
