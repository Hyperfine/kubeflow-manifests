# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE ELASTICACHE CLUSTERS AND ADD CLOUDWATCH ALARMS TO THEM
# This is an example of how to create two ElastiCache Clusters, one running Redis and oen running memcached, and how
# to attach alarms to those clusters that go off if the CPU usage or memory usage get too high.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  # Only this AWS Account ID may be operated on by this template
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ELASTICACHE CLUSTER FOR REDIS
# ---------------------------------------------------------------------------------------------------------------------

module "redis" {
  source = "git::git@github.com:gruntwork-io/module-cache.git//modules/redis?ref=v0.7.0"

  name          = var.redis_cluster_name
  instance_type = "cache.t2.micro"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # We allow connection from anywhere to make it easy to test this example, but in the real world you should NOT do
  # this. Instead, if you're using the Gruntwork VPC setup, you should only allow connections from the CIDR blocks of
  # the private app subnets.
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]

  replication_group_size    = var.redis_replication_group_size
  enable_automatic_failover = false

  sns_topic_for_notifications = ""

  # Since this is just an example, we disable automatic snapshots (also, t2.XXX instances don't support snapshotting)
  snapshot_retention_limit = 0
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ELASTICACHE CLUSTER FOR MEMCACHED
# ---------------------------------------------------------------------------------------------------------------------

module "memcached" {
  source = "git::git@github.com:gruntwork-io/module-cache.git//modules/memcached?ref=v0.7.0"

  name            = var.memcached_cluster_name
  instance_type   = "cache.t2.micro"
  num_cache_nodes = var.memcached_cluster_size

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # We allow connection from anywhere to make it easy to test this example, but in the real world you should NOT do
  # this. Instead, if you're using the Gruntwork VPC setup, you should only allow connections from the CIDR blocks of
  # the private app subnets.
  allow_connections_from_cidr_blocks = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ALARMS FOR THE REDIS ELASTICACHE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "redis_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/elasticache-redis-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/elasticache-redis-alarms"
  cache_cluster_ids    = module.redis.cache_cluster_ids
  num_cluster_ids      = var.redis_replication_group_size
  cache_node_id        = module.redis.cache_node_id
  alarm_sns_topic_arns = [aws_sns_topic.redis_cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ALARMS FOR THE MEMCACHED ELASTICACHE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "memcached_alarms" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/module-aws-monitoring.git//modules/alarms/elasticache-memcached-alarms?ref=v1.0.8"
  source               = "../../modules/alarms/elasticache-memcached-alarms"
  cache_cluster_id     = module.memcached.cache_cluster_id
  cache_node_ids       = module.memcached.cache_node_ids
  num_cache_node_ids   = var.memcached_cluster_size
  alarm_sns_topic_arns = [aws_sns_topic.memcached_cloudwatch_alarms.arn]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SNS TOPICS WHERE ALL ALARM NOTIFICATIONS WILL BE SENT
# You'll need to use the AWS SNS Console to subscribe to this SNS topic so you can receive notifications by email or SMS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "redis_cloudwatch_alarms" {
  name = "${var.redis_cluster_name}-alarms"
}

resource "aws_sns_topic" "memcached_cloudwatch_alarms" {
  name = "${var.memcached_cluster_name}-alarms"
}
