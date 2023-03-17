# ------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# TF_VAR_master_username
# TF_VAR_master_password

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
  default     = "rds-example"
}

variable "master_username" {
  description = "The username for the master user. This should typically be set as the environment variable TF_VAR_master_username so you don't check it into source control."
  type        = string
}

variable "master_password" {
  description = "The password for the master user. This should typically be set as the environment variable TF_VAR_master_password so you don't check it into source control."
  type        = string
}

variable "mysql_engine_version" {
  description = "The MySQL engine version to use."
  type        = string
  default     = "8.0.27"
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values are: alert, audit, error, general, listener, slowquery and trace."
  type        = list(string)
  default     = []
}

variable "create_subnet_group" {
  description = "If false, the DB will bind to an existing aws_db_subnet_group and the CIDR will be ignored (allow_connections_from_cidr_blocks) (default = false)"
  default     = true
  type        = bool
}

variable "aws_db_subnet_group_name" {
  description = "The name of the aws_db_subnet_group that is either created or bound if create_subnet_group=false. Defaults to var.name if not specified."
  type        = string
  default     = null
}
