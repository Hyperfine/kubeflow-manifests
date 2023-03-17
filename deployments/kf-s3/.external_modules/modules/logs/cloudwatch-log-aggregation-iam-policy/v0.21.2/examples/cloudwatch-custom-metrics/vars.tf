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

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS Account."
  type        = string
}

variable "ami" {
  description = "The ID of the AMI to run on the EC2 Instance. It should be built from the Packer template under packer/build.json."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name to use for the EC2 Instance and all other resources created by these templates"
  type        = string
  default     = "cloudwatch-custom-metrics-example"
}

variable "key_pair_name" {
  description = "The name of an EC2 Key Pair to associate with the EC2 Instance. Set to empty string to not associate a Key Pair."
  type        = string
  default     = null
}
