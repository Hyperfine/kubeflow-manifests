# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "rds_db_identifier" {
  description = "The identifier of the RDS database"
  type        = string
}

variable "rds_db_is_aurora_cluster" {
  description = "If set to true, this RDS database is an Amazon Aurora cluster. If set to false, it's running some other database, such as MySQL, Postgres, Oracle, etc."
  type        = bool
}

variable "schedule_expression" {
  description = "An expression that defines how often to run the lambda function to copy snapshots. For example, cron(0 20 * * ? *) or rate(5 minutes)."
  type        = string
}

variable "external_account_id" {
  description = "The ID of the external AWS account that shared the DB snapshots with this account"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "report_cloudwatch_metric" {
  description = "If set true, just before the lambda function finishes running, it will report a custom metric to CloudWatch, as specified by var.report_cloudwatch_metric_namespace and var.report_cloudwatch_metric_name. You can set an alarm on this metric to detect if the backup job failed to run to completion."
  type        = bool
  default     = false
}

variable "report_cloudwatch_metric_namespace" {
  description = "The namespace to use for the the custom CloudWatch metric. Only used if var.report_cloudwatch_metric is set to true."
  type        = string
  default     = null
}

variable "report_cloudwatch_metric_name" {
  description = "The name to use for the the custom CloudWatch metric. Only used if var.report_cloudwatch_metric is set to true."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "The ARN, key ID, or alias of a KMS key to use to encrypt the copied snapshot."
  type        = string
  default     = null
}

variable "lambda_namespace" {
  description = "Namespace all Lambda resources created by this module with this name. If not specified, the default is var.rds_db_identifier with '-copy-snapshot' as a suffix."
  type        = string
  default     = null
}

variable "schedule_namespace" {
  description = "Namespace all Lambda scheduling resources created by this module with this name. If not specified, the default is var.lambda_namespace with '-scheduled' as a suffix."
  type        = string
  default     = null
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}
