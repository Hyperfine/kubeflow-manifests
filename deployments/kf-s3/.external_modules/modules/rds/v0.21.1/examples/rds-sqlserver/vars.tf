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

variable "sqlserver_engine" {
  description = "The SQL Server engine to use."
  type        = string
  default     = "sqlserver-ex"
}

variable "sqlserver_engine_version" {
  description = "The SQL Server engine version to use."
  type        = string
  default     = "15.00.4073.23.v1"
}

variable "sqlserver_port" {
  description = "The SQL Server port to use."
  type        = number
  default     = 1433
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted. The sqlserver engine does not support encryption at rest."
  type        = bool
  default     = false
}
