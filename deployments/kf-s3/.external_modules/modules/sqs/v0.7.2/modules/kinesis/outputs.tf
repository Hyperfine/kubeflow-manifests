output "stream_name" {
  value = aws_kinesis_stream.stream.name
}

output "stream_arn" {
  value = aws_kinesis_stream.stream.arn
}

output "shard_count" {
  value = aws_kinesis_stream.stream.shard_count
}

output "retention_period" {
  value = aws_kinesis_stream.stream.retention_period
}

output "encryption_type" {
  value = aws_kinesis_stream.stream.encryption_type
}

output "enforce_consumer_deletion" {
  value = aws_kinesis_stream.stream.enforce_consumer_deletion
}
