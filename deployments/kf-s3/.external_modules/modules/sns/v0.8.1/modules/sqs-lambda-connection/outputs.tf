output "function_arn" {
  value = length(aws_lambda_event_source_mapping.connection) > 0 ? aws_lambda_event_source_mapping.connection.function_arn : null
}
