# ------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this
# terraform module
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "The name used to namespace all resources created by these templates."
  type        = string
  default     = "efs-example"
}

variable "storage_encrypted" {
  description = "Specifies whether the file system uses encryption for data at rest in the underlying storage. Uses the default aws/elasticfilesystem key in KMS."
  type        = bool
  default     = true
}

variable "transition_to_ia" {
  description = "If specified, files will be transitioned to the IA storage class after the designated time. Valid values: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS."
  type        = string
  default     = "AFTER_7_DAYS"
}

variable "efs_access_points" {
  description = "(Optional) A list of EFS access points to be created and their settings. Each item in the list should be a map compatible with https://www.terraform.io/docs/providers/aws/r/efs_access_point.html."
  type = map(object({
    root_access_arns       = list(string)
    read_write_access_arns = list(string)
    read_only_access_arns  = list(string)
    posix_user = object({
      uid            = number
      gid            = number
      secondary_gids = list(number)
    })
    root_directory = object({
      path        = string
      owner_uid   = number
      owner_gid   = number
      permissions = number
    })
  }))
  default = {
    jenkins = {
      root_access_arns       = []
      read_write_access_arns = []
      read_only_access_arns  = []
      posix_user = {
        uid            = 1000
        gid            = 1000
        secondary_gids = []
      },
      root_directory = {
        path        = "/jenkins"
        owner_uid   = 1000
        owner_gid   = 1000
        permissions = 755
      }
    }
  }
}
