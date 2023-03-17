# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "alarm_configs" {
  description = "A map where the keys are the alarm names and the values are an object with the parameters for that alarm. The supported parameters are the same as the aws_route53_health_check resource. See the comments below for details."
  type        = any
  default     = {}

  # Each entry in the map supports the following attributes:
  #
  # REQUIRED:
  # - domain    [string]: The fully qualified domain name of the endpoint to be checked. (e.g. www.example.com)
  #
  # OPTIONAL (defaults to value of corresponding module input):
  # - port              [number]      : The port of the endpoint to be checked (e.g. 80). Defaults to 80.
  # - type              [string]      : The protocol to use when performing health checks. Valid values are
  #                                   HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED and
  #                                   CLOUDWATCH_METRIC. Defaults to HTTP.
  # - path              [string]      : The path that you want Amazon Route 53 to request when performing
  #                                   health checks (e.g. /status). Defaults to "/".
  # - failure_threshold [number]      :  The number of consecutive health checks that must pass or fail for
  #                                   the health check to declare your site up or down. Defaults to 2.
  # - request_interval  [number]      : The number of seconds between health checks. Defaults to 30.
  # - tags              [map(string)] : A map of tags to apply to the metric alarm. The key is the tag name
  #                                   and the value is the tag value.
}

variable "alarm_sns_topic_arns_us_east_1" {
  description = "A list of SNS topic ARNs to notify when the health check changes to ALARM, OK, or INSUFFICIENT_DATA state. Note: these SNS topics MUST be in us-east-1! This is because Route 53 only sends CloudWatch metrics to us-east-1, so we must create the alarm in that region, and therefore, can only notify SNS topics in that region."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}

variable "provider_role_arn" {
  description = "The optional role_arn to be used in the us-east-1 provider block defined in this module.  This module configures its own AWS provider to ensure resources are created in us-east-1."
  type        = string
  default     = null
}

variable "provider_external_id" {
  description = "The optional external_id to be used in the us-east-1 provider block defined in this module.  This module configures its own AWS provider to ensure resources are created in us-east-1."
  type        = string
  default     = null
}

variable "provider_session_name" {
  description = "The optional session_name to be used in the us-east-1 provider block defined in this module.  This module configures its own AWS provider to ensure resources are created in us-east-1."
  type        = string
  default     = null
}

variable "provider_profile" {
  description = "The optional AWS profile to be used in the us-east-1 provider block defined in this module.  This module configures its own AWS provider to ensure resources are created in us-east-1."
  type        = string
  default     = null
}

variable "provider_shared_credentials_file" {
  description = "The optional path to a credentials file used in the us-east-1 provider block defined in this module.  This module configures its own AWS provider to ensure resources are created in us-east-1."
  type        = string
  default     = null
}
