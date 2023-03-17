output "stream_name" {
  value = module.kinesis.stream_name
}

output "stream_arn" {
  value = module.kinesis.stream_arn
}

output "shard_count" {
  value = module.kinesis.shard_count
}

output "retention_period" {
  value = module.kinesis.retention_period
}

output "encryption_type" {
  value = module.kinesis.encryption_type
}
