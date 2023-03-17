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

variable "storage_encrypted" {
  description = "Specifies whether the DB cluster uses encryption for data at rest in the underlying storage for the DB, its automated backups, Read Replicas, and snapshots. Uses the default aws/rds key in KMS."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "The instance type based on resource requirements. Aurora Global Clusters require instance class of either db.r5 (latest) or db.r4 (current)."
  type        = string
  default     = "db.r5.large"
}

variable "instance_count" {
  description = "How many instances to launch. RDS will automatically pick a leader and configure the others as replicas."
  type        = number
  default     = 1
}

variable "engine" {
  description = "The name of the database engine to be used for this DB cluster. Valid Values: aurora (for MySQL 5.6-compatible Aurora), aurora-mysql (for MySQL 5.7-compatible Aurora), and aurora-postgresql"
  type        = string
  default     = "aurora-mysql"
}

variable "engine_mode" {
  description = "The DB engine mode of the Aurora Global Cluster - global or provisioned, global engine mode only applies for global database clusters created with Aurora MySQL version 5.6.10a. For higher Aurora MySQL versions, the clusters in a global database use provisioned engine mode."
  type        = string
  default     = "provisioned"
}

variable "engine_version" {
  description = "Engine version of the Aurora global database."
  type        = string
  default     = "5.7.mysql_aurora.2.08.1"
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true."
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
