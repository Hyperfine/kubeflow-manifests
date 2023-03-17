# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "rds_db_identifier" {
  description = "The identifier of the RDS database"
  type        = string
}

variable "rds_db_arn" {
  description = "The ARN of the RDS database"
  type        = string
}

variable "rds_db_is_aurora_cluster" {
  description = "If set to true, this RDS database is an Amazon Aurora cluster. If set to false, it's running some other database, such as MySQL, Postgres, Oracle, etc."
  type        = bool
}

variable "schedule_expression" {
  description = "An expression that defines how often to run the lambda function to take snapshots. For example, cron(0 20 * * ? *) or rate(5 minutes)."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "share_snapshot_with_another_account" {
  description = "If set to true, after this lambda function takes a snapshot of the RDS DB, it will trigger the lambda function specified in var.share_snapshot_lambda_arn to share the snapshot with another AWS account."
  type        = bool
  default     = false
}

variable "share_snapshot_lambda_arn" {
  description = "The ARN of a lambda job to trigger to share the DB snapshot with another AWS account. Only used if var.share_snapshot_with_another_account is set to true."
  type        = string
  default     = null
}

variable "share_snapshot_with_account_id" {
  description = "The ID of an AWS account with which to share the RDS snapshot. Only used if var.share_snapshot_with_another_account is set to true."
  type        = string
  default     = null
}

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

variable "max_retries" {
  description = "If the DB is not in available state when this function runs, it will retry up to max_retries times."
  type        = number
  default     = 60
}

variable "sleep_between_retries_sec" {
  description = "The amount of time, in seconds, between retries."
  type        = number
  default     = 60
}

variable "lambda_namespace" {
  description = "Namespace all Lambda resources created by this module with this name. If not specified, the default is var.rds_db_identifier with '-create-snapshot' as a suffix."
  type        = string
  default     = null
}

variable "schedule_namespace" {
  description = "Namespace all Lambda scheduling resources created by this module with this name. If not specified, the default is var.lambda_namespace with '-scheduled' as a suffix."
  type        = string
  default     = null
}

variable "snapshot_namespace" {
  description = "Namespace all snapshots created by this module's jobs with this suffix. If not specified, only the database identifier and timestamp are used."
  type        = string
  default     = ""
}

variable "create_resources" {
  description = "Set to false to have this module skip creating resources. This weird parameter exists solely because Terraform does not support conditional modules. Therefore, this is a hack to allow you to conditionally decide if this module should create anything or not."
  type        = bool
  default     = true
}
