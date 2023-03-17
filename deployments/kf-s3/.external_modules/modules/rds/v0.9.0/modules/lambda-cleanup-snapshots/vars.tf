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

variable "max_snapshots" {
  description = "The maximum number of snapshots to keep around of the given DB. Once this number is exceeded, this lambda function will delete the oldest snapshots."
  type        = number
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "allow_delete_all" {
  description = "If set to true, you will be able to set max_snasphots to zero, and the cleanup lambda job will be allowed to delete ALL snapshots. In production usage, you will NEVER want to set this to true."
  type        = bool
  default     = false
}

variable "lambda_namespace" {
  description = "Namespace all Lambda resources created by this module with this name. If not specified, the default is var.rds_db_identifier with '-delete-snapshots' as a suffix."
  type        = string
  default     = null
}

variable "schedule_namespace" {
  description = "Namespace all Lambda scheduling resources created by this module with this name. If not specified, the default is var.lambda_namespace with '-scheduled' as a suffix."
  type        = string
  default     = null
}
