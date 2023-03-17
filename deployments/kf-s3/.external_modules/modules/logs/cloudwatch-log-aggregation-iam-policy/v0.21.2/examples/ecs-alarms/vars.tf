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

variable "vpc_id" {
  description = "The ID of the VPC where the ECS Cluster should run"
  type        = string
}

variable "environment_name" {
  description = "The name of the VPC where the ECS Cluster should run"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the ECS Cluster should run"
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_instance_ami" {
  description = "The ID of the AMI that should run on each Instance in the ECS Cluster. The AMI should run ECS Optimized Amazon Linux."
  type        = string

  # Amazon ECS-Optimized Amazon Linux AMI 2016.03.d, us-east-1
  default = "ami-dab37fb7"
}

variable "cluster_name" {
  description = "The name of the ECS Cluster"
  type        = string
  default     = "ecs-alarms-example-cluster"
}

variable "service_name" {
  description = "The name of the ECS Service to run in the ECS Cluster"
  type        = string
  default     = "ecs-alarms-example-service"
}
