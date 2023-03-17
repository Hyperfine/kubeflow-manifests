# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the SNS topic."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

# NOTE: Maximum allowed length for display name is 100 characters.
variable "display_name" {
  description = "The display name of the SNS topic. NOTE: Maximum length is 100 characters."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of key value pairs to apply as tags to the SNS topic."
  type        = map(string)
  default     = {}
}

variable "allow_publish_accounts" {
  description = "A list of IAM ARNs that will be given the rights to publish to the SNS topic."
  type        = list(string)
  default     = []
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:role/jenkins"
  # ]
}

variable "allow_publish_services" {
  description = "A list of AWS services that will be given the rights to publish to the SNS topic."
  type        = list(string)
  default     = []
  # Example:
  # default = [
  #   "events.amazonaws.com"
  # ]
}

variable "allow_subscribe_accounts" {
  description = "A list of IAM ARNs that will be given the rights to subscribe to the SNS topic."
  type        = list(string)
  default     = []
  # Example:
  # default = [
  #   "arn:aws:iam::123445678910:role/jenkins"
  # ]
}

variable "allow_subscribe_protocols" {
  description = "A list of protocols that are allowed for subscription."
  type        = list(string)
  default = [
    "http",
    "https",
    "email",
    "email-json",
    "sms",
    "sqs",
    "application",
    "lambda",
  ]
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK"
  type        = string
  default     = null
}

variable "create_resources" {
  description = "Enable or disable creation of the resources of this module. Necessary workaround when it is desired to set count = 0 for modules, which is necessary to maintain backward compatibility with Terraform 0.12.26."
  type        = bool
  default     = true
}
