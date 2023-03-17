output "topic_name" {
  value = length(aws_sns_topic.topic) > 0 ? aws_sns_topic.topic[0].name : null
}

output "topic_display_name" {
  value = var.create_resources ? format("%.100s", var.display_name) : null
}

output "topic_arn" {
  value = length(aws_sns_topic.topic) > 0 ? aws_sns_topic.topic[0].arn : null
}

output "topic_policy" {
  value = (
    length(aws_sns_topic_policy.topic_policy) > 0
    ? aws_sns_topic_policy.topic_policy[0].policy
    : length(aws_sns_topic.topic) > 0 ? aws_sns_topic.topic[0].policy : null
  )
}
