# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  description = "A unique name to use for resources. Set to a semi-random string by tests."
  default     = "example"
}

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be set.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  type = string
}

variable "backup_service_role_name" {
  type        = string
  description = "The name to use for the backup service role that is created and attached to backup plans."
}
