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

variable "storage_encrypted" {
  description = "Specifies whether the DB cluster uses encryption for data at rest in the underlying storage for the DB, its automated backups, Read Replicas, and snapshots. Uses the default aws/rds key in KMS."
  type        = bool
  default     = false
}

variable "engine_mode" {
  description = "The version of aurora to run - global, provisioned or serverless."
  type        = string
  default     = "global"
}

variable "is_primary" {
  description = "Determines whether or not to create an RDS global cluster. If true, then it creates the global cluster with a primary else it only creates a secondary cluster."
  type        = bool
  default     = false
}

variable "source_region" {
  description = "Source region for global secondary cluster."
  type        = string
  default     = null
}

variable "global_cluster_identifier" {
  description = "Global cluster identifier when creating the global secondary cluster."
  type        = string
  default     = null
}

variable "engine_version" {
  description = " Engine version of the Aurora global database."
  type        = string
  default     = "5.6.10a"
}
