# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# TF_VAR_master_username
# TF_VAR_master_password

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account."
  type        = string
}

variable "master_username" {
  description = "The username for the master user."
  type        = string
}

variable "master_password" {
  description = "The password for the master user."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which the DB should be created."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnets in which the DB should run. If using the standard Gruntwork VPC, these should be the IDs of the private persistence subnets."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "db_name" {
  description = "The name to use for the RDS instance and all other resources created by these templates"
  type        = string
  default     = "rds-alarms-example"
}
