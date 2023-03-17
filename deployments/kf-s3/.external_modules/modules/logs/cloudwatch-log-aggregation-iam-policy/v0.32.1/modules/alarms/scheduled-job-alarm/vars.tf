# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the scheduled job"
  type        = string
}

variable "namespace" {
  description = "The namespace of this metric in CloudWatch (e.g. AWS/EC2)"
  type        = string
}

variable "metric_name" {
  description = "The name of the metric"
  type        = string
}

variable "period" {
  description = "How often the metric should be updated, in seconds (e.g. at least once per day = 86400)"
  type        = number
}

variable "alarm_sns_topic_arns" {
  description = "A list of SNS topic ARNs to notify when the ELB alarms change to ALARM, OK, or INSUFFICIENT_DATA state"
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE CONSTANTS
# These variables rarely change
# ---------------------------------------------------------------------------------------------------------------------

variable "threshold" {
  description = "The minimum value the metric should maintain. For scheduled jobs, it usually only makes sense to set this to 1, as that requires the job runs at least once per var.period."
  type        = number
  default     = 1
}

variable "unit" {
  description = "The unit for this metric (e.g. Count). For scheduled jobs, it usually only makes sense to set this to Count, as we are just counting how many times the job has run per var.period."
  type        = string
  default     = "Count"
}

variable "evaluation_periods" {
  description = "How many consecutive periods (defined by var.period) the metric can drop below var.threshold before the alarm goes off. Usually, you want to know if even a single scheduled job fails, so we default this to 1."
  type        = number
  default     = 1
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