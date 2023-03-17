output "redis_alarm_sns_topic_arn" {
  value = aws_sns_topic.redis_cloudwatch_alarms.arn
}

output "memcached_alarm_sns_topic_arn" {
  value = aws_sns_topic.memcached_cloudwatch_alarms.arn
}

output "memcached_cache_addresses" {
  value = module.memcached.cache_addresses
}

output "memcached_cache_cluster_id" {
  value = module.memcached.cache_cluster_id
}

output "memcached_cache_node_ids" {
  value = module.memcached.cache_node_ids
}

output "memcached_configuration_endpoint" {
  value = module.memcached.configuration_endpoint
}

output "memcached_cache_port" {
  value = module.memcached.cache_port
}

output "redis_cache_port" {
  value = module.redis.cache_port
}

output "redis_cache_cluster_ids" {
  value = module.redis.cache_cluster_ids
}

output "redis_cache_node_id" {
  value = module.redis.cache_node_id
}

output "redis_primary_endpoint" {
  value = module.redis.primary_endpoint
}

output "redis_read_endpoint" {
  value = module.redis.reader_endpoint
}
