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
  description = "The ID of the VPC in which the ElasitCache cluster should be created."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnets in which the ElastiCache cluster should run. If using the standard Gruntwork VPC, these should be the IDs of the private persistence subnets."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# DEFINE CONSTANTS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "redis_cluster_name" {
  description = "The name to use for the redis ElastiCache cluster and all other resources created by these templates"
  type        = string
  default     = "redis-example"
}

variable "memcached_cluster_name" {
  description = "The name to use for the memcached ElastiCache cluster and all other resources created by these templates"
  type        = string
  default     = "memcached-example"
}

variable "redis_replication_group_size" {
  description = "The total number of nodes in the Redis Replication Group. E.g. 1 represents just the primary node, 2 represents the primary plus a single Read Replica."
  type        = number
  default     = 2
}

variable "memcached_cluster_size" {
  description = "The number of nodes to have in the memcached cluster"
  type        = number
  default     = 2
}
