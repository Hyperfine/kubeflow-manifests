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
  default     = "aurora-example"
}

variable "master_username" {
  description = "The username for the master user. This should typically be set as the environment variable TF_VAR_master_username so you don't check it into source control."
  type        = string
}

variable "master_password" {
  description = "The password for the master user. This should typically be set as the environment variable TF_VAR_master_password so you don't check it into source control."
  type        = string
}

variable "instance_count" {
  description = "How many instances to launch. RDS will automatically pick a leader and configure the others as replicas."
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "The instance type to use for the db (e.g. db.r3.large)"
  type        = string
  default     = "db.t3.medium"
}

variable "storage_encrypted" {
  description = "Specifies whether the DB cluster uses encryption for data at rest in the underlying storage for the DB, its automated backups, Read Replicas, and snapshots. Uses the default aws/rds key in KMS."
  type        = bool
  default     = true
}

variable "engine_mode" {
  description = "The version of aurora to run - provisioned or serverless."
  type        = string
  default     = "provisioned"
}

variable "apply_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window. Note that cluster modifications may cause degraded performance or downtime."
  type        = bool
  default     = true
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
