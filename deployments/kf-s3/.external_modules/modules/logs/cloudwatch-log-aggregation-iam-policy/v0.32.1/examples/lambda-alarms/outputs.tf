output "function_name" {
  description = "Unique name for Lambda Function"
  value       = module.lambda_function.function_name
}

output "function_arn" {
  description = "Amazon Resource Name (ARN) identifying the Lambda Function"
  value       = module.lambda_function.function_arn
}

output "sns_topic_arn" {
  description = "Amazon Resource Name (ARN) of the SNS Topic that is used by the alarm"
  value       = aws_sns_topic.failure_topic.arn
}

output "alarm_name" {
  description = "Name of the Cloudwatch alarm"
  value       = module.lambda_alarm.alarm_name
}

output "alarm_arn" {
  description = "ARN of the Cloudwatch alarm"
  value       = module.lambda_alarm.alarm_arn
}

output "alarm_actions" {
  description = "The list of actions to execute when this alarm transitions into an ALARM state from any other state"
  value       = module.lambda_alarm.alarm_actions
}

output "ok_actions" {
  description = "The list of actions to execute when this alarm transitions into an OK state from any other state"
  value       = module.lambda_alarm.ok_actions
}

output "insufficient_data_actions" {
  description = "The list of actions to execute when this alarm transitions into an INSUFFICIENT_DATA state from any other state"
  value       = module.lambda_alarm.insufficient_data_actions
}
