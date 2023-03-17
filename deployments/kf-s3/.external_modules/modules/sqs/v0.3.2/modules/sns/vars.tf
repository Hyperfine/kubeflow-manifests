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

# NOTE: Although the API allows setting a display name longer than 10 characters, the AWS Console actually displays
# an error when editing the value, so we limit it to 10 characters here
variable "display_name" {
  description = "The display name of the SNS topic. NOTE: Maximum length is 10 characters."
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

variable "create_resources" {
  description = "Enable or disable creation of the resources of this module. Necessary workaround when it is desired to set count = 0 for modules, which is not yet possible as of terraform 0.12.17"
  type        = bool
  default     = true
}
