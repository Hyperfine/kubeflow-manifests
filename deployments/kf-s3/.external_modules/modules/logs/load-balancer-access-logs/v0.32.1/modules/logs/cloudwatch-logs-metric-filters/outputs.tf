output "metric_filter_names" {
  description = "The name of the Cloudwatch Logs Metric Filter"
  value       = [for metric_filter in aws_cloudwatch_log_metric_filter.metric_filter : metric_filter.name]
}

output "alarm_names" {
  description = "The name of the Cloudwatch Metric alarm."
  value       = [for metric_alarm in aws_cloudwatch_metric_alarm.metric_alarm : metric_alarm.alarm_name]
}

output "alarm_arns" {
  description = "The ARN of the Cloudwatch Metric alarm."
  value       = [for metric_alarm in aws_cloudwatch_metric_alarm.metric_alarm : metric_alarm.arn]
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic associated with the Cloudwatch Metric alarm"
  value       = local.sns_topic_arn
}
