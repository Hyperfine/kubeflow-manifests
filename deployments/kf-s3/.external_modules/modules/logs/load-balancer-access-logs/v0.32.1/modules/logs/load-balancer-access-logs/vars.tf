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

variable "bucket_policy_statements" {
  # The bucket policy statements for this S3 bucket. See the 'statement' block in the aws_iam_policy_document data
  # source for context: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  #
  # bucket_policy_statements is a map where the keys are the statement IDs (SIDs) and the values are objects that can
  # define the following properties:
  #
  # - effect                                      string            (optional): Either "Allow" or "Deny", to specify whether this statement allows or denies the given actions.
  # - actions                                     list(string)      (optional): A list of actions that this statement either allows or denies. For example, ["s3:GetObject", "s3:PutObject"].
  # - not_actions                                 list(string)      (optional): A list of actions that this statement does NOT apply to. Used to apply a policy statement to all actions except those listed.
  # - principals                                  map(list(string)) (optional): The principals to which this statement applies. The keys are the principal type ("AWS", "Service", or "Federated") and the value is a list of identifiers.
  # - not_principals                              map(list(string)) (optional): The principals to which this statement does NOT apply. The keys are the principal type ("AWS", "Service", or "Federated") and the value is a list of identifiers.
  # - keys                                        list(string)      (optional): A list of keys within the bucket to which this policy applies. For example, ["", "/*"] would apply to (a) the bucket itself and (b) all keys within the bucket. The default is [""].
  # - condition                                   map(object)       (optional): A nested configuration block (described below) that defines a further, possibly-service-specific condition that constrains whether this statement applies.
  #
  # condition is a map from a unique ID for the condition to an object that can define the following properties:
  #
  # - test                                        string            (required): The name of the IAM condition operator to evaluate.
  # - variable                                    string            (required): The name of a Context Variable to apply the condition to. Context variables may either be standard AWS variables starting with aws:, or service-specific variables prefixed with the service name.
  # - values                                      list(string)      (required):  The values to evaluate the condition against. If multiple values are provided, the condition matches if at least one of them applies. (That is, the tests are combined with the "OR" boolean operation.)
  description = "The IAM policy to apply to this S3 bucket. You can use this to grant read/write access. This should be a map, where each key is a unique statement ID (SID), and each value is an object that contains the parameters defined in the comment above."

  # Ideally, this would be a map(object({...})), but the Terraform object type constraint doesn't support optional
  # parameters, whereas IAM policy statements have many optional params. And we can't even use map(any), as the
  # Terraform map type constraint requires all values to have the same type ("shape"), but as each object in the map
  # may specify different optional params, this won't work either. So, sadly, we are forced to fall back to "any."
  type = any

  # Example:
  #
  # {
  #    AllIamUsersReadAccess = {
  #      effect     = "Allow"
  #      actions    = ["s3:GetObject"]
  #      principals = {
  #        AWS = ["arn:aws:iam::111111111111:user/ann", "arn:aws:iam::111111111111:user/bob"]
  #      }
  #    }
  # }
  default = {}
}

## S3 Bucket access log

variable "enable_s3_server_access_logging" {
  description = "Enables S3 server access logging which sends detailed records for the requests that are made to the bucket. Defaults to false."
  type        = bool
  default     = false
}

variable "s3_server_access_logging_bucket" {
  description = "The S3 bucket where access logs for this bucket should be stored. When non-empty, the module will assume the s3 bucket already exists. When null, the module will create a new S3 bucket with a name derived from var.s3_bucket_name. Only used if var.enable_s3_server_access_logging is true."
  type        = string
  default     = null
}

variable "s3_server_access_logging_prefix" {
  description = "A prefix (i.e., folder path) to use for all access logs stored in s3_server_access_logging_bucket. Only used if var.enable_s3_server_access_logging is true."
  type        = string
  default     = null
}

variable "s3_server_access_logging_bucket_force_destroy" {
  description = "A boolean that indicates whether the bucket for storing S3 server access logs should be destroyed, even if there are files in it, when you run Terraform destroy. Unless you are using this bucket only for test purposes, you'll want to leave this variable set to false."
  type        = bool
  default     = false
}

# S3 bucket object locking

variable "object_lock_enabled" {
  description = "Set to true to enable Object Locking. This prevents objects from being deleted for a customizable period of time. Note that this MUST be configured at bucket creation time - you cannot update an existing bucket to enable object locking unless you go through AWS support. Additionally, this is not reversible - once a bucket is created with object lock enabled, you cannot disable object locking even with this setting. Note that enabling object locking will automatically enable bucket versioning."
  type        = bool
  default     = false
}

variable "object_lock_default_retention_enabled" {
  description = "Set to true to configure a default retention period for object locks when Object Locking is enabled. When disabled, objects will not be protected with locking by default unless explicitly configured at object creation time. Only used if object_lock_enabled is true."
  type        = bool
  default     = true
}

variable "object_lock_mode" {
  description = "The default Object Lock retention mode you want to apply to new objects placed in this bucket. Valid values are GOVERNANCE and COMPLIANCE. Only used if object_lock_enabled and object_lock_default_retention_enabled are true."
  type        = string
  default     = null
}

variable "object_lock_days" {
  description = "The number of days that you want to specify for the default retention period for Object Locking. Only one of object_lock_days or object_lock_years can be configured. Only used if object_lock_enabled and object_lock_default_retention_enabled are true."
  type        = number
  default     = null
}

variable "object_lock_years" {
  description = "The number of years that you want to specify for the default retention period for Object Locking. Only one of object_lock_days or object_lock_years can be configured. Only used if object_lock_enabled and object_lock_default_retention_enabled are true."
  type        = number
  default     = null
}

variable "s3_server_access_logging_bucket_object_lock_enabled" {
  description = "Set to true to enable Object Locking on the S3 bucket used to store S3 server access logs. Refer to var.object_lock_enabled for more details on the implications of object locking."
  type        = bool
  default     = false
}

variable "s3_server_access_logging_bucket_object_lock_default_retention_enabled" {
  description = "Set to true to configure a default retention period for object locks when Object Locking is enabled on the S3 server access logs bucket. Refer to var.object_lock_default_retention_enabled for more details on the implications of object locking default retention."
  type        = bool
  default     = true
}

variable "s3_server_access_logging_bucket_object_lock_mode" {
  description = "The default Object Lock retention mode you want to apply to new objects placed in the bucket S3 server access logs bucket. Refer to var.object_lock_mode for more details on supported lock modes."
  type        = string
  default     = null
}

variable "s3_server_access_logging_bucket_object_lock_days" {
  description = "The number of days that you want to specify for the default retention period for Object Locking on the S3 server access logs bucket. Refer to var.object_lock_days for more details."
  type        = number
  default     = null
}

variable "s3_server_access_logging_bucket_object_lock_years" {
  description = "The number of years that you want to specify for the default retention period for Object Locking on the S3 server access logs bucket. Refer to var.object_lock_years for more details."
  type        = number
  default     = null
}

## Meta configuration variables

variable "create_resources" {
  description = "Set to false to have this module create no resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if the S3 buckets should be created or not."
  type        = bool
  default     = true
}
