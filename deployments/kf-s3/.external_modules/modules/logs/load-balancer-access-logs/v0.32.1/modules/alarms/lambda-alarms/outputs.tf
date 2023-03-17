# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARM OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "alarm_name" {
  description = "Name of the Cloudwatch alarm"
  value       = length(var.alarm_sns_topic_arns) > 0 ? aws_cloudwatch_metric_alarm.lambda_alarm[0].alarm_name : null
}

output "alarm_arn" {
  description = "ARN of the Cloudwatch alarm"
  value       = length(var.alarm_sns_topic_arns) > 0 ? aws_cloudwatch_metric_alarm.lambda_alarm[0].arn : null
}

output "alarm_actions" {
  description = "The list of actions to execute when this alarm transitions into an ALARM state from any other state"
  # alarm_actions is a set so, without flatten(), we end up with a list of a set.
  # This way we end up with a single list.
  value = length(var.alarm_sns_topic_arns) > 0 ? flatten(aws_cloudwatch_metric_alarm.lambda_alarm[0].alarm_actions) : null
}

output "ok_actions" {
  description = "The list of actions to execute when this alarm transitions into an OK state from any other state"
  # ok_actions is a set so, without flatten(), we end up with a list of a set.
  # This way we end up with a single list.
  value = length(var.alarm_sns_topic_arns) > 0 ? flatten(aws_cloudwatch_metric_alarm.lambda_alarm[0].ok_actions) : null
}

output "insufficient_data_actions" {
  description = "The list of actions to execute when this alarm transitions into an INSUFFICIENT_DATA state from any other state"
  # insufficiente_data_actions is a set so, without flatten(), we end up with a list of a set.
  # This way we end up with a single list.
  value = length(var.alarm_sns_topic_arns) > 0 ? flatten(aws_cloudwatch_metric_alarm.lambda_alarm[0].insufficient_data_actions) : null
}
