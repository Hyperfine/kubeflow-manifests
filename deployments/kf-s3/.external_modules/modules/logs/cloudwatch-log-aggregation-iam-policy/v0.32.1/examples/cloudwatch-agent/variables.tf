# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "ami" {
  description = "The ID of the AMI to run on the EC2 Instance. It should be built from the Packer template under packer/build.json."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "The name to use for the EC2 Instance and all other resources created by these templates"
  type        = string
  default     = "cloudwatch-log-aggregation-example"
}

variable "text_to_log" {
  description = "The text the User Data script on the EC2 Instance will log to syslog when the instance boots up. This is useful for seeing some known text flow all the way through to CloudWatch Logs."
  type        = string
  default     = "This is text logged from the CloudWatch Log Aggregation example"
}

variable "key_name" {
  description = "Name of the EC2 keypair to use to configure SSH access."
  type        = string
  default     = null
}
