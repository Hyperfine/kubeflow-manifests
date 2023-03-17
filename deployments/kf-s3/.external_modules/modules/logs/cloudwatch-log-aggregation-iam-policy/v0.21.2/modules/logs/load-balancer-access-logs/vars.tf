# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "s3_bucket_name" {
  description = "The name to use for the S3 bucket. Must be globally unique."
  type        = string
}

variable "s3_logging_prefix" {
  description = "The prefix specified in the ELB's or ALB's logging configuration. All logs are stored in this folder name (prefix) in the S3 Bucket, and it must match the ALB name in order to have access."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "force_destroy" {
  description = "A boolean that indicates whether this bucket should be destroyed, even if there are files in it, when you run Terraform destroy. Unless you are using this bucket only for test purposes, you'll want to leave this variable set to false."
  type        = bool
  default     = false
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

variable "tags" {
  description = "A map of tags to apply to the S3 Bucket. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "create_resources" {
  description = "Set to false to have this module create no resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if the S3 buckets should be created or not."
  type        = bool
  default     = true
}

variable "s3_bucket_policy" {
  description = "The optional policy to the apply to the S3 bucket created, overriding the default bucket policy"
  type        = string
  default     = null
}
