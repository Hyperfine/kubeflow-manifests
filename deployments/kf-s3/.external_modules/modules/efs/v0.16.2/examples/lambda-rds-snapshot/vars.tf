# ------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# TF_VAR_master_username
# TF_VAR_master_password

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "master_username" {
  description = "The username for the master user. This should typically be set as the environment variable TF_VAR_master_username so you don't check it into source control."
  type        = string
}

variable "master_password" {
  description = "The password for the master user. This should typically be set as the environment variable TF_VAR_master_password so you don't check it into source control."
  type        = string
}

variable "external_account_id" {
  description = "The ID of the external AWS account with which DB snapshots will be shared"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name used to namespace all resources created by these templates."
  type        = string
  default     = "example"
}

variable "max_snapshots" {
  description = "The maximum number of snapshots to keep around of the given DB. Once this number is exceeded, this lambda function will delete the oldest snapshots."
  type        = number
  default     = 15
}

variable "allow_delete_all" {
  description = "If set to true, you will be able to set max_snasphots to zero, and the cleanup lambda job will be allowed to delete ALL snapshots. In production usage, you will NEVER want to set this to true."
  type        = bool
  default     = false
}

variable "allow_connections_from_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that can connect to this DB. In the standard Gruntwork VPC setup, these should be the CIDR blocks of the private persistence subnets, plus the private subnets in the mgmt VPC."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "schedule_expression" {
  description = "An expression that defines how often to run the lambda function to take snapshots. For example, cron(0 20 * * ? *) or rate(5 minutes)."
  type        = string
  default     = "rate(1 day)"
}

variable "enable_snapshot" {
  description = "Set to false to have this module skip setting up lambda functions for managing snapshots."
  type        = bool
  default     = true
}
