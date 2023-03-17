output "metric_filter_names" {
  description = "The name of the Cloudwatch Logs Metric Filter"
  value       = module.cloudwatch_logs_metric_filter.metric_filter_names
}

output "alarm_names" {
  description = "The name of the Cloudwatch Metric alarm."
  value       = module.cloudwatch_logs_metric_filter.alarm_names
}

output "alarm_arns" {
  description = "The ARN of the Cloudwatch Metric alarm."
  value       = module.cloudwatch_logs_metric_filter.alarm_arns
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic where cloudwatch."
  value       = module.cloudwatch_logs_metric_filter.sns_topic_arn
}
