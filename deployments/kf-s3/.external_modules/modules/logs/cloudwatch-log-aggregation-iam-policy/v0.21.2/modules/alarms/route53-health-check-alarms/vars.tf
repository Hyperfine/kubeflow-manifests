# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "domain" {
  description = "The fully qualified domain name of the endpoint to be checked. (e.g. www.example.com)"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARM DEFAULTS
# ---------------------------------------------------------------------------------------------------------------------

variable "port" {
  description = "The port of the endpoint to be checked. (e.g. 80)"
  type        = number
  default     = 80
}

variable "type" {
  description = "The protocol to use when performing health checks. Valid values are HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED and CLOUDWATCH_METRIC."
  type        = string
  default     = "HTTP"
}

variable "path" {
  description = "The path that you want Amazon Route 53 to request when performing health checks. (e.g. /status)"
  type        = string
  default     = "/"
}

variable "failure_threshold" {
  description = "The number of consecutive health checks that must pass or fail for the health check to declare your site up or down"
  type        = number
  default     = 2
}

variable "request_interval" {
  description = "The number of seconds between health checks"
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arns_us_east_1" {
  description = "A list of SNS topic ARNs to notify when the health check changes to ALARM, OK, or INSUFFICIENT_DATA state. Note: these SNS topics MUST be in us-east-1! This is because Route 53 only sends CloudWatch metrics to us-east-1, so we must create the alarm in that region, and therefore, can only notify SNS topics in that region."
  type        = list(string)
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to the metric alarm. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}
