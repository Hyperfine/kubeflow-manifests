# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "nlb_name" {
  description = "The name of the NLB. Do not include the environment name since this module will automatically append it to the value of this variable."
  type        = string
  default     = "nlb-no-logs-example"
}

variable "environment_name" {
  description = "The environment name in which the NLB is located. (e.g. stage, prod)"
  type        = string
  default     = "test"
}
