# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "rds_db_arn" {
  description = "The ARN of the RDS database"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name for the lambda function and other resources created by these Terraform configurations"
  type        = string
  default     = "share-rds-snapshot"
}

variable "max_retries" {
  description = "The maximum number of retries the lambda function will make while waiting for the snapshot to be available"
  type        = number
  default     = 60
}

variable "sleep_between_retries_sec" {
  description = "The amount of time, in seconds, between retries."
  type        = number
  default     = 60
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}
