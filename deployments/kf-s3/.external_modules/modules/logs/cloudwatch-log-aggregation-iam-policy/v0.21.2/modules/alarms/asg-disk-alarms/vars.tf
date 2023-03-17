# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the ELB alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

variable "asg_names" {
  description = "The name of the ASG"
  type        = list(string)
}

variable "num_asg_names" {
  description = "The number of names in var.asg_names. We should be able to compute this automatically, but can't due to a Terraform limitation (https://github.com/hashicorp/terraform/issues/4149)."
  type        = number
}

variable "file_system" {
  description = "The file system being monitored (e.g. /dev/disk/foo)"
  type        = string
}

variable "mount_path" {
  description = "The mount path of the file system being monitored (e.g. /)"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARM DEFAULTS
# ---------------------------------------------------------------------------------------------------------------------

variable "high_disk_utilization_threshold" {
  description = "Trigger an alarm if the EC2 Instances in this ASG have a disk utilization percentage above this threshold"
  type        = number
  default     = 90
}

variable "high_disk_utilization_period" {
  description = "The period, in seconds, over which to measure the disk utilization percentage"
  type        = number
  default     = 300
}

variable "high_disk_utilization_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "high_disk_utilization_statistic" {
  description = "The statistic to apply to the alarm's associated metric. [SampleCount, Average, Sum, Minimum, Maximum]"
  type        = string
  default     = "Maximum"
}

variable "treat_missing_data" {
  description  = "Sets how this alarm should handle entering the INSUFFICIENT_DATA state. Based on https://goo.gl/cxzXOV. Must be one of: 'missing', 'ignore', 'breaching' or 'notBreaching'."
  type         = string
  default      = "missing"
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