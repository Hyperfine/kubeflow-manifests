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
  default     = "nlb-submap-example"
}

variable "environment_name" {
  description = "The environment name in which the NLB is located. (e.g. stage, prod)"
  type        = string
  default     = "test"
}

# Config for the example server

variable "example_server_name_prefix" {
  description = "Names for resources related to the example server will be prefixed with this string."
  type        = string
  default     = ""
}

variable "example_server_keypair_name" {
  description = "The SSH keypair to use for the example server."
  type        = string
  default     = null
}

variable "server_text" {
  description = "The text to return for the example server when connecting to it."
  type        = string
  default     = "Hello World!"
}

variable "server_port" {
  description = "The port that the example server should listen on."
  type        = number
  default     = 8080
}

variable "num_days_after_which_archive_log_data" {
  description = "After this number of days, log files should be transitioned from S3 to Glacier. Enter 0 to never archive log data."
  type        = number
  default     = 30
}

variable "num_days_after_which_delete_log_data" {
  description = "After this number of days, log files should be deleted from S3. Enter 0 to never delete log data."
  type        = number
  default     = 0
}

variable "force_destroy_access_logs_s3_bucket" {
  description = "A boolean that indicates whether the S3 Bucket used to store NLB logs should be destroyed, even if there are files in it, when you run Terraform destroy. Unless you are using this NLB only for test purposes, you'll want to leave this variable set to false."
  type        = bool
  default     = false
}
