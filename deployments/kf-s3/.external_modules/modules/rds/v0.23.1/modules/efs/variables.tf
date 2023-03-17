# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be passed in by the templates using this module.
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name used to namespace all resources created by these templates, including the EFS file system. Must be unique for this region. May contain only lowercase alphanumeric characters, hyphens, underscores, periods, and spaces."
  type        = string
}

variable "vpc_id" {
  description = "The id of the VPC in which this file system should be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet ids where the file system should be deployed. In the standard Gruntwork VPC setup, these should be the private persistence subnet ids."
  type        = list(string)
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables may be optionally passed in by the templates using this module to overwite the defaults.
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_efs_security_group_name" {
  description = "The name of the aws_efs_security_group that is created. Defaults to var.name if not specified."
  type        = string
  default     = null
}

variable "aws_efs_security_group_description" {
  description = "The description of the aws_efs_security_group that is created. Defaults to 'Security group for the var.name file system' if not specified."
  type        = string
  default     = null
}

variable "allow_connections_from_security_groups" {
  description = "A list of Security Groups that can connect to this file system."
  type        = list(string)
  default     = []
}

variable "allow_connections_from_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that can connect to this file system. Should typically be the CIDR blocks of the private app subnet in this VPC plus the private subnet in the mgmt VPC."
  type        = list(string)
  default     = []
}

variable "storage_encrypted" {
  description = "Specifies whether the EFS file system is encrypted."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN of a KMS key that should be used to encrypt data on disk. Only used if var.storage_encrypted is true. If you leave this blank, the default EFS KMS key for the account will be used."
  type        = string
  default     = null
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the EFS file system and the Security Group created for it. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "performance_mode" {
  description = "The file system performance mode. Can be either \"generalPurpose\" or \"maxIO\". For more details: https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Valid values: \"bursting\", \"provisioned\". When using \"provisioned\", also set \"provisioned_throughput_in_mibps\"."
  type        = string
  default     = "bursting"
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with \"throughput_mode\" set to \"provisioned\"."
  type        = number
  default     = null
}

variable "transition_to_ia" {
  description = "If specified, files will be transitioned to the IA storage class after the designated time. Valid values: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS."
  type        = string
  default     = null
}

variable "enforce_in_transit_encryption" {
  description = "Enforce in-transit encryption for all clients connecting to this EFS file system. If set to true, any clients connecting without in-transit encryption will be denied via an IAM policy."
  type        = bool
  default     = true
}

variable "efs_access_points" {
  description = "(Optional) A list of EFS access points to be created and their settings. This is a map where the keys are the access point names and the values are objects that should have the fields described in https://www.terraform.io/docs/providers/aws/r/efs_access_point.html."
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
  default = {}

  # Example:
  # efs_access_points = {
  #   jenkins = {
  #     root_access_arns = []
  #     read_write_access_arns = [
  #       "arn:aws:iam::123456789101:role/jenkins-iam-role",
  #     ]
  #     read_only_access_arns = []
  #     posix_user = {
  #       uid            = 1000
  #       gid            = 1000
  #       secondary_gids = []
  #     },
  #     root_directory = {
  #       path = "/jenkins"
  #       owner_uid   = 1000
  #       owner_gid   = 1000
  #       permissions = 755
  #     }
  #   }
  # }
}

variable "allow_access_via_mount_target" {
  description = "(Optional) Allow access to the EFS file system via mount targets. If set to true, any clients connecting to a mount target (i.e. from within the private app subnet) will be allowed access."
  type        = bool
  default     = false
}
